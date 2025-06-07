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
    while kubectl get $resource_type $resource_name -n $namespace 2>/dev/null; do
        sleep 5
    done
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

# Remover recursos do namespace monitoring
kubectl delete all --all -n monitoring
kubectl delete servicemonitor --all -n monitoring
kubectl delete pvc --all -n monitoring
kubectl delete namespace monitoring

# Remover recursos do namespace app
kubectl delete all --all -n app
kubectl delete namespace app

# 2. Remover recursos do EKS
echo -e "${YELLOW}Removendo recursos do EKS...${NC}"

cd terraform-eks

# Remover Karpenter e Node Groups primeiro
terraform destroy -target=module.karpenter -target=module.node_group -auto-approve
check_error "Falha ao remover Karpenter e Node Groups"

# Remover Load Balancer Controller e outros componentes
terraform destroy -target=module.aws-load-balancer-controller -target=module.externaldns -target=module.ebs_csi_driver -auto-approve
check_error "Falha ao remover Load Balancer Controller e outros componentes"

# Remover o cluster EKS
terraform destroy -target=module.cluster_eks -auto-approve
check_error "Falha ao remover o cluster EKS"

# 3. Remover recursos de rede
echo -e "${YELLOW}Removendo recursos de rede...${NC}"

# Remover Elastic IPs
remove_elastic_ips

# Forçar remoção de recursos de rede
force_remove_network_resources

# Aguardar um pouco para garantir que todos os recursos foram removidos
sleep 30

# Remover o estado do Terraform para os recursos problemáticos
echo -e "${YELLOW}Removendo estado do Terraform para recursos problemáticos...${NC}"
terraform state rm module.network.aws_internet_gateway.igw
terraform state rm module.network.aws_subnet.public[0]
terraform state rm module.network.aws_subnet.public[1]
terraform state rm module.network.aws_vpc.vpc

# Remover o módulo de rede
terraform destroy -target=module.network -auto-approve
check_error "Falha ao remover recursos de rede"

# 4. Remover todos os recursos restantes
echo -e "${YELLOW}Removendo todos os recursos restantes...${NC}"
terraform destroy -auto-approve
check_error "Falha ao remover recursos restantes"

cd ..

echo -e "${GREEN}Processo de destruição concluído com sucesso!${NC}" 