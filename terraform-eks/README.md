# stack-terraform-eks-module

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.56.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.14.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.31.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws-load-balancer-controller"></a> [aws-load-balancer-controller](#module\_aws-load-balancer-controller) | ./modules/aws-loadbalancer-controller | n/a |
| <a name="module_cluster_eks"></a> [cluster\_eks](#module\_cluster\_eks) | ./modules/eks-cluster | n/a |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | ./modules/karpenter | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |
| <a name="module_node_group"></a> [node\_group](#module\_node\_group) | ./modules/node-group | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_iam_role_node"></a> [aws\_iam\_role\_node](#output\_aws\_iam\_role\_node) | n/a |
| <a name="output_certificate_authority"></a> [certificate\_authority](#output\_certificate\_authority) | CA do cluster EKS |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | n/a |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Nome do cluster EKS |
| <a name="output_eks_vpc_config"></a> [eks\_vpc\_config](#output\_eks\_vpc\_config) | Configuracoes de vpc, subnets do EKS |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Endpoint do cluster EKS |
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | ARN do Internet Gateway |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | ID do Internet Gateway |
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | Lista de allocation ID de Elastic IPs criados para AWS NAT Gateway |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | ID do Nat Gateway |
| <a name="output_natgw_interface_ids"></a> [natgw\_interface\_ids](#output\_natgw\_interface\_ids) | ID da interface associada ao NAT Gateways |
| <a name="output_oidc"></a> [oidc](#output\_oidc) | Url do OIDC do cluster EKS |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | Tls certificate do cluster EKS |
| <a name="output_private_subnet"></a> [private\_subnet](#output\_private\_subnet) | IDs das subnets privadas |
| <a name="output_public_subnet"></a> [public\_subnet](#output\_public\_subnet) | IDs das subnets publicas |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | Idendificador da VPC |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN da VPC |
