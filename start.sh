#!/bin/bash

echo "Digite escolha um nome para o repositório ECR: "
read reposit
# aws ecr create-repository --repository-name $reposit
sed -i -e "s/\$repository/$reposit/g" ./.github/workflows/pipe.yaml

echo "Digite um nome para o cluster Kubernetes EKS: "
read cluster
sed -i -e "s/\$cluster_n/$cluster/g" ./terraform-eks/variables.tf 
sed -i -e "s/\$cluster_n/$cluster/g" ./.github/workflows/pipe.yaml

echo "Digite nome do seu bucket: "
read bucket
sed -i -e "s/\$buck/$bucket/g" ./terraform-eks/backend.tf 

echo "Digite o ID da sua Conta AWS: "
read accountID
sed -i -e "s/\$account/$accountID/g" ./.github/workflows/pipe.yaml

# File default
# echo "Deseja voltar aos valores padrões (s/n)?"
# read resposta

# if [ "$resposta" == "s" ]; then
#       sed -i -e "s/$reposit/\$repository/g" ./.github/workflows/pipe.yaml
#       sed -i -e "s/$cluster/\$cluster_n/g" ./terraform-eks/variables.tf 
#       sed -i -e "s/$cluster/\$cluster_n/g" ./.github/workflows/pipe.yaml
#       sed -i -e "s/$bucket/\$buck/g" ./terraform-eks/backend.tf
#       sed -i -e "s/$accountID/\$account/g" ./.github/workflows/pipe.yaml
# else:
#       echo "Nenhuma alteração foi feita"
# fi