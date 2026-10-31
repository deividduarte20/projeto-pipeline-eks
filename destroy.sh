#!/usr/bin/env bash

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-devops}"
CLUSTER_NAME="${CLUSTER_NAME:-${PROJECT_NAME}-cluster}"
VPC_NAME="${VPC_NAME:-${PROJECT_NAME}-vpc}"
TF_DIR="${TF_DIR:-terraform-eks}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
  echo -e "${YELLOW}$1${NC}"
}

warn() {
  echo -e "${RED}$1${NC}" >&2
}

die() {
  warn "$1"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatório não encontrado: $1"
}

confirm_destroy() {
  if [ "${FORCE_DESTROY:-0}" = "1" ]; then
    return 0
  fi

  echo -e "${RED}ATENÇÃO: este script destrói o cluster ${CLUSTER_NAME} e os recursos do projeto ${PROJECT_NAME} na região ${AWS_REGION}.${NC}"
  read -r -p "Digite 'destroy' para continuar: " confirmation
  [ "$confirmation" = "destroy" ] || die "Operação cancelada."
}

get_vpc_id() {
  aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=${VPC_NAME}" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null | grep -v '^None$' || true
}

delete_project_load_balancers() {
  local vpc_id="$1"

  [ -n "$vpc_id" ] || return 0

  log "Removendo Load Balancers da VPC ${vpc_id}..."
  mapfile -t lb_arns < <(
    aws elbv2 describe-load-balancers \
      --region "$AWS_REGION" \
      --query "LoadBalancers[?VpcId=='${vpc_id}'].LoadBalancerArn" \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^None$/d;/^$/d'
  )

  if [ "${#lb_arns[@]}" -eq 0 ]; then
    log "Nenhum Load Balancer encontrado."
    return 0
  fi

  for lb_arn in "${lb_arns[@]}"; do
    log "Removendo Load Balancer ${lb_arn}..."
    aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$lb_arn" || warn "Falha ao remover ${lb_arn}."
  done

  aws elbv2 wait load-balancers-deleted --region "$AWS_REGION" --load-balancer-arns "${lb_arns[@]}" || warn "Timeout aguardando remoção dos Load Balancers."
}

release_project_elastic_ips() {
  local vpc_id="$1"
  local allocation_id

  log "Removendo Elastic IPs gerenciados pelo projeto..."
  mapfile -t allocation_ids < <(
    {
      aws ec2 describe-addresses \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=eip-${PROJECT_NAME}*" \
        --query 'Addresses[].AllocationId' \
        --output text 2>/dev/null

      if [ -n "$vpc_id" ]; then
        aws ec2 describe-nat-gateways \
          --region "$AWS_REGION" \
          --filter "Name=vpc-id,Values=${vpc_id}" \
          --query 'NatGateways[].NatGatewayAddresses[].AllocationId' \
          --output text 2>/dev/null
      fi
    } | tr '\t' '\n' | sed '/^None$/d;/^$/d' | sort -u
  )

  for allocation_id in "${allocation_ids[@]}"; do
    log "Liberando Elastic IP ${allocation_id}..."
    aws ec2 release-address --region "$AWS_REGION" --allocation-id "$allocation_id" || warn "Falha ao liberar ${allocation_id}."
  done
}

delete_application_namespaces() {
  local namespace

  if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
    log "kubectl indisponível ou cluster inacessível. Pulando limpeza do Kubernetes."
    return 0
  fi

  log "Removendo NodePools do Karpenter para impedir criação de novos nós..."
  kubectl delete nodepool default --ignore-not-found --timeout=120s || warn "Falha ao remover NodePool default."
  kubectl delete ec2nodeclass default --ignore-not-found --timeout=120s || warn "Falha ao remover EC2NodeClass default."

  for namespace in app monitoring; do
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
      log "Namespace ${namespace} não existe. Pulando."
      continue
    fi

    log "Removendo namespace ${namespace}..."
    if ! kubectl delete namespace "$namespace" --timeout=300s; then
      warn "Namespace ${namespace} não foi removido no prazo. Removendo finalizer apenas deste namespace."
      kubectl patch namespace "$namespace" -p '{"metadata":{"finalizers":null}}' --type=merge || true
      kubectl delete namespace "$namespace" --force --grace-period=0 || true
    fi
  done
}

run_terraform_destroy() {
  terraform -chdir="$TF_DIR" destroy -auto-approve -lock-timeout=5m
}

main() {
  confirm_destroy
  require_command aws
  require_command terraform

  aws sts get-caller-identity >/dev/null 2>&1 || die "Credenciais AWS inválidas ou ausentes."
  [ -d "$TF_DIR" ] || die "Diretório ${TF_DIR} não encontrado."

  local vpc_id
  vpc_id="$(get_vpc_id)"

  log "Inicializando Terraform..."
  terraform -chdir="$TF_DIR" init -input=false

  delete_application_namespaces

  delete_project_load_balancers "$vpc_id"

  log "Executando Terraform Destroy..."
  if ! run_terraform_destroy; then
    warn "Terraform Destroy falhou. Tentando novamente após limpar Load Balancers e Elastic IPs remanescentes."
    delete_project_load_balancers "$vpc_id"
    release_project_elastic_ips "$vpc_id"
    run_terraform_destroy || die "Terraform Destroy falhou novamente. Verifique os recursos remanescentes manualmente."
  fi

  log "Removendo Elastic IPs remanescentes do projeto..."
  release_project_elastic_ips "$vpc_id"

  vpc_id="$(get_vpc_id)"
  if [ -n "$vpc_id" ]; then
    die "A VPC ${VPC_NAME} (${vpc_id}) ainda existe. Verifique os recursos remanescentes no console/CLI."
  fi

  echo -e "${GREEN}Processo de destruição concluído com sucesso.${NC}"
}

main "$@"
