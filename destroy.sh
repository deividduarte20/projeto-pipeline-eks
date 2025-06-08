#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando processo de destruição...${NC}"

# Função para verificar se um comando foi executado com sucesso
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro: $1${NC}"
        exit 1
    fi
}

# Função para forçar a remoção de recursos pendentes
force_remove_pending_resources() {
    local namespace=$1
    echo -e "${YELLOW}Forçando remoção de recursos pendentes no namespace $namespace...${NC}"
    
    # Remove pods em estado Pending
    kubectl get pods -n $namespace -o name | grep -v "No resources found" | while read -r pod; do
        echo -e "${YELLOW}Removendo pod $pod...${NC}"
        kubectl delete $pod -n $namespace --force --grace-period=0
    done

    # Remove deployments
    kubectl get deployments -n $namespace -o name | grep -v "No resources found" | while read -r deployment; do
        echo -e "${YELLOW}Removendo deployment $deployment...${NC}"
        kubectl delete $deployment -n $namespace --force --grace-period=0
    done

    # Remove daemonsets
    kubectl get daemonsets -n $namespace -o name | grep -v "No resources found" | while read -r daemonset; do
        echo -e "${YELLOW}Removendo daemonset $daemonset...${NC}"
        kubectl delete $daemonset -n $namespace --force --grace-period=0
    done

    # Remove services
    kubectl get services -n $namespace -o name | grep -v "No resources found" | while read -r service; do
        echo -e "${YELLOW}Removendo service $service...${NC}"
        kubectl delete $service -n $namespace --force --grace-period=0
    done

    # Remove PVCs
    kubectl get pvc -n $namespace -o name | grep -v "No resources found" | while read -r pvc; do
        echo -e "${YELLOW}Removendo PVC $pvc...${NC}"
        kubectl delete $pvc -n $namespace --force --grace-period=0
    done

    # Remove CRDs específicos que podem estar causando problemas
    kubectl get crd | grep -E 'externaldns|karpenter|prometheus|grafana' | awk '{print $1}' | while read -r crd; do
        echo -e "${YELLOW}Removendo CRD $crd...${NC}"
        kubectl delete crd $crd --force --grace-period=0
    done
}

# Função para forçar a remoção do namespace externaldns
force_remove_externaldns() {
    echo -e "${YELLOW}Forçando remoção do namespace externaldns...${NC}"
    
    # 1. Remover todos os recursos
    kubectl delete all --all -n externaldns --force --grace-period=0 2>/dev/null || true
    kubectl delete pvc --all -n externaldns --force --grace-period=0 2>/dev/null || true
    kubectl delete servicemonitor --all -n externaldns --force --grace-period=0 2>/dev/null || true
    
    # 2. Remover CRDs relacionados ao externaldns
    kubectl get crd | grep -E 'externaldns' | awk '{print $1}' | while read -r crd; do
        kubectl delete crd $crd --force --grace-period=0
    done
    
    # 3. Tentar remover via API diretamente
    echo -e "${YELLOW}Tentando remover namespace externaldns via API...${NC}"
    
    # Obter o token de autenticação
    TOKEN=$(kubectl get secret -n kube-system $(kubectl get serviceaccount -n kube-system default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode)
    
    # Obter o endpoint da API
    API_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    
    # Remover o namespace via API
    curl -k -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$API_ENDPOINT/api/v1/namespaces/externaldns" \
        -d '{"kind":"DeleteOptions","apiVersion":"v1","propagationPolicy":"Background"}' || true
    
    # 4. Se ainda existir, tentar remover finalizers via API
    if kubectl get namespace externaldns &>/dev/null; then
        echo -e "${YELLOW}Tentando remover finalizers via API...${NC}"
        
        # Obter o namespace em JSON
        kubectl get namespace externaldns -o json > externaldns.json
        
        # Remover finalizers
        sed -i 's/"finalizers": \[[^]]\+\]/"finalizers": []/' externaldns.json
        
        # Aplicar via API
        curl -k -X PUT \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            "$API_ENDPOINT/api/v1/namespaces/externaldns/finalize" \
            -d @externaldns.json || true
        
        rm externaldns.json
    fi
    
    # 5. Forçar remoção do namespace
    kubectl delete namespace externaldns --force --grace-period=0
    
    # 6. Aguardar um pouco
    sleep 5
    
    # 7. Se ainda existir, tentar uma última vez
    if kubectl get namespace externaldns &>/dev/null; then
        echo -e "${YELLOW}Tentando última remoção forçada...${NC}"
        kubectl patch namespace externaldns -p '{"metadata":{"finalizers":[]}}' --type=merge
        kubectl delete namespace externaldns --force --grace-period=0
    fi
}

# Função para remover finalizers de um namespace
remove_namespace_finalizers() {
    local namespace=$1
    
    # Ignora o namespace default, externaldns e karpenter
    if [ "$namespace" = "default" ] || [ "$namespace" = "externaldns" ] || [ "$namespace" = "karpenter" ]; then
        echo -e "${YELLOW}Pulando namespace $namespace...${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Removendo finalizers do namespace $namespace...${NC}"
    
    # Verifica se o namespace existe
    if ! kubectl get namespace $namespace &>/dev/null; then
        echo -e "${YELLOW}Namespace $namespace não existe, pulando...${NC}"
        return 0
    fi

    # Força remoção de recursos pendentes primeiro
    force_remove_pending_resources $namespace

    # 1. Obter o nome do namespace em formato JSON
    kubectl get namespace $namespace -o json > ${namespace}.json

    # 2. Editar o arquivo para remover os finalizers
    sed -i 's/"finalizers": \[[^]]\+\]/"finalizers": []/' ${namespace}.json

    # 3. Aplicar o arquivo modificado
    kubectl replace --raw "/api/v1/namespaces/${namespace}/finalize" -f ${namespace}.json

    # 4. Remover o arquivo temporário
    rm ${namespace}.json

    # 5. Forçar remoção do namespace
    kubectl delete namespace $namespace --force --grace-period=0

    # 6. Aguardar um pouco para garantir que o namespace foi removido
    sleep 5

    # 7. Verificar se o namespace ainda existe e tentar remover novamente se necessário
    if kubectl get namespace $namespace &>/dev/null; then
        echo -e "${YELLOW}Namespace $namespace ainda existe, tentando remover novamente...${NC}"
        kubectl patch namespace $namespace -p '{"metadata":{"finalizers":[]}}' --type=merge
        kubectl delete namespace $namespace --force --grace-period=0
    fi

    echo -e "${GREEN}Finalizers do namespace $namespace removidos com sucesso${NC}"
}

# Função para esperar recursos serem removidos
wait_for_deletion() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local timeout=300  # 5 minutos de timeout
    
    echo -e "${YELLOW}Aguardando remoção de $resource_name...${NC}"
    local start_time=$(date +%s)
    
    while kubectl get $resource_type $resource_name -n $namespace 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            echo -e "${RED}Timeout ao aguardar remoção de $resource_name${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}Ainda aguardando... ($elapsed segundos)${NC}"
        sleep 10
    done
    
    echo -e "${GREEN}$resource_name removido com sucesso${NC}"
    return 0
}

# Função para remover namespace com timeout
remove_namespace() {
    local namespace=$1
    
    # Ignora o namespace default, externaldns e karpenter
    if [ "$namespace" = "default" ] || [ "$namespace" = "externaldns" ] || [ "$namespace" = "karpenter" ]; then
        echo -e "${YELLOW}Pulando namespace $namespace...${NC}"
        return 0
    fi
    
    local timeout=300  # 5 minutos de timeout
    
    # Verifica se o namespace existe
    if ! kubectl get namespace $namespace &>/dev/null; then
        echo -e "${YELLOW}Namespace $namespace não existe, pulando...${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Removendo namespace $namespace...${NC}"
    
    # Remove todos os recursos do namespace
    echo -e "${YELLOW}Removendo recursos do namespace $namespace...${NC}"
    kubectl delete all --all -n $namespace 2>/dev/null || true
    kubectl delete pvc --all -n $namespace 2>/dev/null || true
    kubectl delete servicemonitor --all -n $namespace 2>/dev/null || true
    
    # Remove os finalizers antes de tentar remover o namespace
    remove_namespace_finalizers $namespace
    
    # Tenta remover o namespace
    echo -e "${YELLOW}Tentando remover namespace $namespace...${NC}"
    kubectl delete namespace $namespace
    
    # Aguarda a remoção
    local start_time=$(date +%s)
    while kubectl get namespace $namespace &>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            echo -e "${RED}Timeout ao remover namespace $namespace${NC}"
            echo -e "${YELLOW}Tentando forçar remoção...${NC}"
            remove_namespace_finalizers $namespace
            kubectl delete namespace $namespace --force --grace-period=0
            return 1
        fi
        
        echo -e "${YELLOW}Ainda aguardando remoção do namespace... ($elapsed segundos)${NC}"
        sleep 10
    done
    
    echo -e "${GREEN}Namespace $namespace removido com sucesso${NC}"
    return 0
}

# Função para remover endereços IP públicos
remove_elastic_ips() {
    echo -e "${YELLOW}Removendo Elastic IPs...${NC}"
    
    # Lista todos os Elastic IPs
    EIP_ALLOCATIONS=$(aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text)
    
    for ALLOC_ID in $EIP_ALLOCATIONS; do
        # Desassocia o EIP primeiro
        ASSOC_ID=$(aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query 'Addresses[0].AssociationId' --output text)
        if [ ! -z "$ASSOC_ID" ] && [ "$ASSOC_ID" != "None" ]; then
            aws ec2 disassociate-address --association-id $ASSOC_ID
            sleep 5
        fi
        
        # Remove o EIP
        aws ec2 release-address --allocation-id $ALLOC_ID
    done
}

# Função para forçar a remoção de recursos de rede
force_remove_network_resources() {
    echo -e "${YELLOW}Forçando remoção de recursos de rede...${NC}"
    
    # Obtém o ID da VPC
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query 'Vpcs[0].VpcId' --output text)
    
    if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        # Remove Load Balancers
        echo -e "${YELLOW}Removendo Load Balancers...${NC}"
        LBS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)
        for LB_ARN in $LBS; do
            aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
            echo -e "${YELLOW}Aguardando Load Balancer $LB_ARN ser removido...${NC}"
            aws elbv2 wait load-balancers-deleted --load-balancer-arns $LB_ARN
        done

        # Remove NAT Gateways
        echo -e "${YELLOW}Removendo NAT Gateways...${NC}"
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text)
        for NAT_ID in $NAT_GATEWAYS; do
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
            echo -e "${YELLOW}Aguardando NAT Gateway $NAT_ID ser removido...${NC}"
            aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_ID
        done

        # Remove Network Interfaces
        echo -e "${YELLOW}Removendo Network Interfaces...${NC}"
        ENIS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
        for ENI_ID in $ENIS; do
            aws ec2 delete-network-interface --network-interface-id $ENI_ID --force
        done

        # Remove Route Tables
        echo -e "${YELLOW}Removendo Route Tables...${NC}"
        RTBS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].RouteTableId' --output text)
        for RTB_ID in $RTBS; do
            # Remove todas as rotas exceto a rota local
            aws ec2 describe-route-tables --route-table-ids $RTB_ID --query 'RouteTables[0].Routes[?DestinationCidrBlock!=`172.31.0.0/16`].RouteTableId' --output text | while read -r route; do
                aws ec2 delete-route --route-table-id $RTB_ID --destination-cidr-block $route
            done
            aws ec2 delete-route-table --route-table-id $RTB_ID
        done

        # Remove Security Groups
        echo -e "${YELLOW}Removendo Security Groups...${NC}"
        SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
        for SG_ID in $SGS; do
            aws ec2 delete-security-group --group-id $SG_ID
        done

        # Remove Subnets
        echo -e "${YELLOW}Removendo Subnets...${NC}"
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
        for SUBNET_ID in $SUBNETS; do
            aws ec2 delete-subnet --subnet-id $SUBNET_ID
        done

        # Remove Internet Gateway
        echo -e "${YELLOW}Removendo Internet Gateway...${NC}"
        IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
        if [ ! -z "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --force
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
        fi

        # Remove VPC
        echo -e "${YELLOW}Removendo VPC...${NC}"
        aws ec2 delete-vpc --vpc-id $VPC_ID --force
    fi
}

# 1. Remover recursos do Kubernetes
echo -e "${YELLOW}Removendo recursos do Kubernetes...${NC}"

# Verificar se o kubectl está configurado
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}Erro: kubectl não está configurado ou não consegue acessar o cluster${NC}"
    echo -e "${YELLOW}Pulando remoção de recursos do Kubernetes...${NC}"
else
    # Remover finalizers de todos os namespaces antes de começar
    echo -e "${YELLOW}Removendo finalizers de todos os namespaces...${NC}"
    for namespace in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        remove_namespace_finalizers $namespace
    done

    # Remover recursos do namespace monitoring
    remove_namespace "monitoring"

    # Remover recursos do namespace app
    remove_namespace "app"

    # Aguardar um pouco para garantir que o kubectl terminou todas as operações
    echo -e "${YELLOW}Aguardando kubectl finalizar operações...${NC}"
    sleep 10
fi

# 2. Remover recursos do EKS
echo -e "${YELLOW}Removendo recursos do EKS...${NC}"

# Verificar se o diretório terraform-eks existe
if [ ! -d "terraform-eks" ]; then
    echo -e "${RED}Diretório terraform-eks não encontrado!${NC}"
    echo -e "${YELLOW}Verificando diretório atual...${NC}"
    pwd
    ls -la
    exit 1
fi

echo -e "${YELLOW}Entrando no diretório terraform-eks...${NC}"
cd terraform-eks || {
    echo -e "${RED}Falha ao entrar no diretório terraform-eks${NC}"
    exit 1
}

# Verificar se o Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform não está instalado!${NC}"
    exit 1
fi

echo -e "${YELLOW}Inicializando Terraform...${NC}"
terraform init || {
    echo -e "${RED}Falha ao inicializar Terraform${NC}"
    exit 1
}

# Remover Karpenter e Node Groups primeiro
echo -e "${YELLOW}Removendo Karpenter e Node Groups...${NC}"
terraform destroy -target=module.karpenter -target=module.node_group -auto-approve || {
    echo -e "${RED}Falha ao remover Karpenter e Node Groups${NC}"
    exit 1
}

# Remover Load Balancer Controller e outros componentes
echo -e "${YELLOW}Removendo Load Balancer Controller e outros componentes...${NC}"
terraform destroy -target=module.aws-load-balancer-controller -target=module.ebs_csi_driver -auto-approve || {
    echo -e "${RED}Falha ao remover Load Balancer Controller e outros componentes${NC}"
    exit 1
}

# Remover o cluster EKS
echo -e "${YELLOW}Removendo o cluster EKS...${NC}"
terraform destroy -target=module.cluster_eks -auto-approve || {
    echo -e "${RED}Falha ao remover o cluster EKS${NC}"
    exit 1
}

# 3. Remover recursos de rede
echo -e "${YELLOW}Removendo recursos de rede...${NC}"

# Remover Elastic IPs
remove_elastic_ips

# Forçar remoção de recursos de rede
force_remove_network_resources

# Aguardar um pouco para garantir que todos os recursos foram removidos
echo -e "${YELLOW}Aguardando 30 segundos para garantir que todos os recursos foram removidos...${NC}"
sleep 30

# Remover o estado do Terraform para os recursos problemáticos
echo -e "${YELLOW}Removendo estado do Terraform para recursos problemáticos...${NC}"
terraform state rm module.network.aws_internet_gateway.igw 2>/dev/null || true
terraform state rm module.network.aws_subnet.public[0] 2>/dev/null || true
terraform state rm module.network.aws_subnet.public[1] 2>/dev/null || true
terraform state rm module.network.aws_vpc.vpc 2>/dev/null || true

# Remover o módulo de rede
echo -e "${YELLOW}Removendo módulo de rede...${NC}"
terraform destroy -target=module.network -auto-approve || {
    echo -e "${RED}Falha ao remover recursos de rede${NC}"
    exit 1
}

# 4. Remover todos os recursos restantes
echo -e "${YELLOW}Removendo todos os recursos restantes...${NC}"
terraform destroy -auto-approve || {
    echo -e "${RED}Falha ao remover recursos restantes${NC}"
    exit 1
}

cd ..

echo -e "${GREEN}Processo de destruição concluído com sucesso!${NC}"
