#!/bin/bash

echo "Digite escolha um nome para o repositório ECR: "
read reposit
aws ecr create-repository --repository-name $reposit
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