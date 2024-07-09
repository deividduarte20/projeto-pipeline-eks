# Terraform EKS

### Objetivo

#### Consiste em provisionar AWS EKS, deployment, service e hpa utilizando o provider helm no terraform.

#### Baixe o repositório
```bash
git clone https://github.com/deividduarte20/terraform-eks.git
```

#### Entre no diretório

```bash
cd terraform-eks
```

<img src=img/warning2.png width=25 height=25 /> Altere os valores das variáveis da pasta raiz no arquivo variables.tf.

#### Inicie o terraform

```bash
terraform init
```

#### Aplique a infraestrutura como código

```bash
terraform apply
```

#### Verifique os nodes
```bash
kubectl get nodes
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.49.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.13.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.30.0 |


## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_aws_load_balancer_controller"></a> [eks\_aws\_load\_balancer\_controller](#module\_eks\_aws\_load\_balancer\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_eks_cluster"></a> [eks\_cluster](#module\_eks\_cluster) | ./modules/cluster | n/a |
| <a name="module_eks_managed_node_group"></a> [eks\_managed\_node\_group](#module\_eks\_managed\_node\_group) | ./modules/managed-node-group | n/a |
| <a name="module_eks_network"></a> [eks\_network](#module\_eks\_network) | ./modules/network | n/a |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | Networking CIDR block to be used for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project Name to be used in Tags | `string` | `"projeto-eks"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster"></a> [eks\_cluster](#output\_eks\_cluster) | n/a |
<!-- END_TF_DOCS -->
