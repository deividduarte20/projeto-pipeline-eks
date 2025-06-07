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

# Função para remover registros DNS no Route 53
remove_route53_records() {
    echo -e "${YELLOW}Removendo registros DNS no Route 53...${NC}"
    
    # Substitua pela sua Hosted Zone ID
    HOSTED_ZONE_ID="SUA_HOSTED_ZONE_ID"  # Ex.: Z1234567890ABC
    if [ -z "$HOSTED_ZONE_ID" ] || [ "$HOSTED_ZONE_ID" == "SUA_HOSTED_ZONE_ID" ]; then
        echo -e "${YELLOW}Hosted Zone ID não configurada, pulando remoção de registros DNS${NC}"
        return 0
    fi

    # Lista todos os registros na Hosted Zone
    RECORD_SETS=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query 'ResourceRecordSets[?Type==`A` || Type==`CNAME`].Name' --output text)
    
    for RECORD in $RECORD_SETS; do
        # Cria um arquivo JSON para deletar o registro
        cat << EOF > delete-record.json
{
  "Comment": "Delete record set created by ExternalDNS",
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "$RECORD",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": []
      }
    }
  ]
}
EOF
        aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://delete-record.json
        check_error "Falha ao remover registro DNS $RECORD"
    done
    rm -f delete-record.json
}

# Função para remover endereços IP públicos
remove_elastic_ips() {
    echo -e "${YELLOW}Removendo Elastic IPs associados à VPC...${NC}"
    
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query 'Vpcs[0].VpcId' --output text)
    check_error "Falha ao obter ID da VPC"
    
    if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
        echo -e "${YELLOW}Nenhuma VPC encontrada com a tag eks-vpc${NC}"
        return 0
    fi

    EIP_ALLOCATIONS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[*].AllocationId' --output text)
    
    for ALLOC_ID in $EIP_ALLOCATIONS; do
        ASSOC_ID=$(aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query 'Addresses[0].AssociationId' --output text)
        if [ ! -z "$ASSOC_ID" ] && [ "$ASSOC_ID" != "None" ]; then
            aws ec2 disassociate-address --association-id $ASSOC_ID
            check_error "Falha ao disassociar EIP $ALLOC_ID"
            sleep 5
        fi
        aws ec2 release-address --allocation-id $ALLOC_ID
        check_error "Falha ao remover EIP $ALLOC_ID"
    done
}

# Função para forçar a remoção de recursos de rede
force_remove_network_resources() {
    echo -e "${YELLOW}Forçando remoção de recursos de rede...${NC}"
    
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
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text)
    for NAT_ID in $NAT_GATEWAYS; do
        aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
        check_error "Falha ao remover NAT Gateway $NAT_ID"
        echo -e "${YELLOW}Aguardando NAT Gateway $NAT_ID ser removido...${NC}"
        aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_ID || true
    done

    # Remove Network Interfaces
    echo -e "${YELLOW}Removendo Network Interfaces...${NC}"
    ENIS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
    for ENI_ID in $ENIS; do
        aws ec2 delete-network-interface --network-interface-id $ENI_ID || true
    done

    # Remove Route Tables
    echo -e "${YELLOW}Removendo Route Tables...${NC}"
    RTBS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].RouteTableId' --output text)
    for RTB_ID in $RTBS; do
        ROUTES=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query 'RouteTables[0].Routes[?DestinationCidrBlock!=`172.31.0.0/16`].DestinationCidrBlock' --output text)
        for ROUTE in $ROUTES; do
            aws ec2 delete-route --route-table-id $RTB_ID --destination-cidr-block $ROUTE || true
        done
        aws ec2 delete-route-table --route-table-id $RTB_ID || true
    done

    # Remove Security Groups
    echo -e "${YELLOW}Removendo Security Groups...${NC}"
    SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
    for SG_ID in $SGS; do
        aws ec2 delete-security-group --group-id $SG_ID || true
    done

    # Remove Subnets
    echo -e "${YELLOW}Removendo Subnets...${NC}"
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    for SUBNET_ID in $SUBNETS; do
        aws ec2 delete-subnet --subnet-id $SUBNET_ID || true
    done

    # Remove Internet Gateway
    echo -e "${YELLOW}Removendo Internet Gateway...${NC}"
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
    if [ ! -z "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID || true
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID || true
    fi

    # Remove VPC
    echo -e "${YELLOW}Removendo VPC...${NC}"
    aws ec2 delete-vpc --vpc-id $VPC_ID || true
}

# Verificar se o diretório terraform-eks existe
if [ ! -d "terraform-eks" ]; then
    echo -e "${RED}Diretório terraform-eks não encontrado!${NC}"
    exit 1
fi

# Remover recursos do EKS
echo -e "${YELLOW}Removendo recursos do EKS...${NC}"

cd terraform-eks || exit 1

# Inicializar Terraform
terraform init
check_error "Falha ao inicializar Terraform"

# Remover registros DNS no Route 53
remove_route53_records

# Remover todos os recursos Terraform
echo -e "${YELLOW}Destruindo todos os recursos Terraform...${NC}"
terraform destroy -auto-approve
check_error "Falha ao destruir recursos Terraform"

# Remover recursos de rede manualmente, se necessário
echo -e "${YELLOW}Verificando recursos de rede remanescentes...${NC}"
remove_elastic_ips
force_remove_network_resources

# Limpar estado do Terraform para recursos problemáticos
echo -e "${YELLOW}Limpando estado do Terraform...${NC}"
terraform state rm module.network.aws_internet_gateway.igw || true
terraform state rm module.network.aws_subnet.public[0] || true
terraform state rm module.network.aws_subnet.public[1] || true
terraform state rm module.network.aws_vpc.vpc || true

cd ..

echo -e "${GREEN}Processo de destruição concluído com sucesso!${NC}"
