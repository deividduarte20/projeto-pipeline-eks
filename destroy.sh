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

# Função para esperar recursos serem removidos
wait_for_deletion() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    echo -e "${YELLOW}Aguardando remoção de $resource_name...${NC}"
    for ((i=0; i<12; i++)); do
        if ! kubectl get $resource_type $resource_name -n $namespace 2>/dev/null; then
            return 0
        fi
        sleep 5
    done
    echo -e "${RED}Timeout aguardando remoção de $resource_name${NC}"
    exit 1
}

# Função para remover endereços IP públicos
remove_elastic_ips() {
    echo -e "${YELLOW}Removendo Elastic IPs associados à VPC...${NC}"
    
    # Obtém o ID da VPC
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query 'Vpcs[0].VpcId' --output text)
    check_error "Falha ao obter ID da VPC"
    
    if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
        echo -e "${YELLOW}Nenhuma VPC encontrada com a tag eks-vpc${NC}"
        return 0
    fi

    # Lista Elastic IPs associados à VPC
    EIP_ALLOCATIONS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[?].AllocationId' --output text)
    
    for ALLOC_ID in $EIP_ALLOCATIONS; do
        # Desassocia o EIP primeiro
        ASSOC_ID=$(aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query 'Addresses[0].AssociationId' --output text)
        if [ ! -z "$ASSOC_ID" ] && [ "$ASSOC_ID" != "None" ]; then
            aws ec2 disassociate-address --association-id $ASSOC_ID
            check_error "Falha ao disassociar EIP $ALLOC_ID"
            sleep 5
        fi
        
        # Remove o EIP
        aws ec2 release-address --allocation-id $ALLOC_ID
        check_error "Falha ao remover EIP $ALLOC_ID"
    done
}

# Função para forçar a remoção de recursos de rede
force_remove_network_resources() {
    echo -e "${YELLOW}Forçando remoção de recursos de rede...${NC}"
    
    # Obtém o ID da VPC
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query 'Vpcs[0].VpcId' --output text)
    
    if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
        echo -e "${YELLOW}Nenhuma VPC encontrada com a tag eks-vpc${NC}"
        return 0
    fi

    # Remove Load Balancers
    echo -e "${YELLOW}Removendo Load Balancers...${NC}"
    LBS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)
    for LB_ARN in $LBS; do
        aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
        check_error "Falha ao remover Load Balancer $LB_ARN"
        echo -e "${YELLOW}Aguardando Load Balancer $LB_ARN ser removido...${NC}"
        aws elbv2 wait load-balancers-deleted --load-balancer-arns $LB_ARN || true
    done

    # Remove NAT Gateways
    echo -e "${YELLOW}Removendo NAT Gateways...${NC}"
    NAT_GATEWAYSS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text
    for NAT_ID in $NAT_GATEWAY; do
        aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
        check_error "Falha ao remover NAT Gateway $$NAT_ID"
        echo -e "${YELLOW}Aguardando NAT Gateway $$NAT_ID ser removido...${NC}"
        aws ec2 wait nat-gateway-deleted --nat-gateway-ids $$NAT_ID || true
    done

    # Remove Network Interfaces
    echo -e "${YELLOW}Removendo Network Interfaces...${NC}"
    ENIS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
    for ENI_ID in $ENIS; do
        aws ec2 delete-network-interface --network-interface-id $ENI_ID
        check_error "Falha ao remover ENI $ENI_ID"
    done

    # Remove Route Tables
    echo -e "${YELLOW}Removendo Route Tables...${NC}"
    RTBS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].RouteTableId' --output text)
    for RTB_ID in $RTBS; do
        # Remove rotas não locais
        ROUTES=$(aws ec2 describe-route-tables --route-table-id $RTB_ID --query 'RouteTables[0].Routes[?DestinationCidrBlock!=`172.31.0.0/16`].DestinationCidrBlock' --output text)
        for ROUTE in $ROUTE; do
            aws ec2 delete-route --route-table-id $RTB_ID --destination-cidr-block $ROUTE
        done
        aws ec2 delete-route-table --route-table-id $RTB_ID
        check_error "Falha ao remover Route Table $RTB_ID"
    done

    # Remove Security Groups
    echo -e "${YELLOW}Removendo Security Groups...${NC}"
    SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
    for SG_ID in $SGS; do
        aws ec2 delete-security-group --group-id $SGID
        check_error "Falha ao remover Security Group $SG_ID"
    done

    # Remove Subnets
    echo -e "${YELLOW}Removendo Subnets...${NC}"
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    for SUBNET_ID in $SUBNETS; do
        aws ec2 delete-subnet --subnet-id $SUBNET_ID
        check_error "Falha ao remover Subnet $SUBNET_ID"
    done

    # Remove Internet Gateway
    echo -e "${YELLOW}Removendo Internet Gateway...${NC}"
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
    if [ ! -z "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
        check_error "Falha ao desanexar Internet Gateway $IGW_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
        check_error "Falha ao remover Internet Gateway $IGW_ID"
    fi

    # Remove VPC
    echo -e "${YELLOW}Removendo VPC...${NC}"
    aws ec2 delete-vpc --vpc-id $VPC_ID
    check_error "Falha ao remover VPC $VPC_ID"
}

# Verificar se o diretório terraform-eks existe
if [ ! -d "terraform-eks" ]; then
    echo -e "${RED}Diretório terraform-eks não encontrado!${NC}"
    exit 1
fi

# Remover recursos do EKS
echo -e "${YELLOW}Removendo recursos do EKS...${NC}"

cd terraform-eks || exit 1

# Remover Karpenter e Node Groups
terraform destroy -target=module.karpenter -target=module.node_group -auto-approve
check_error "Falha ao remover Karpenter e Node Groups"

# Remover Load Balancer Controller e outros componentes
terraform destroy -target=module.aws-load-balancer-controller -target=module.externaldns -target=module.ebs_csi_driver -auto-approve
check_error "Falha ao remover Load Balancer Controller e outros componentes"

# Remover o cluster EKS
terraform destroy -target=module.cluster_eks -auto-approve
check_error "Falha ao remover o cluster EKS"

# Remover recursos de rede
echo -e "${YELLOW}Removendo recursos de rede...${NC}"

# Remover Elastic IPs
remove_elastic_ips

# Forçar remoção de recursos de rede
force_remove_network_resources

# Remova o estado do Terraform para recursos problemáticos
echo -e "${YELLOW}Removendo estado do Terraform para recursos problemáticos...${NC}"
terraform state rm module.network.aws_internet_gateway.gw
check_error "Falha ao remover estado do Internet Gateway"
terraform state rm module.network.aws_subnet.public[0]
check_error "Falha ao remover estado da subnet pública 0"
terraform state rm module.network.aws_subnet.public[1]
check_error "Falha ao remover estado da subnet pública 1"
terraform state rm module.network.aws_vpc.vpc
check_error "Falha ao remover estado da VPC"

# Remover o módulo de rede
terraform destroy -target=module.network -auto-approve
check_error "Falha ao destruir módulo de rede"

# Remover todos os recursos
echo -e "${YELLOW}Removendo todos os recursos restantes...${NC}"
terraform destroy -auto-approve
check_error "Falha ao destruir recursos restantes"

cd ..

echo -e "${GREEN}Processo de destruição concluído com sucesso!${NC}"
