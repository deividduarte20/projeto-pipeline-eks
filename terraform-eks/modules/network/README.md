## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.57.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_vpc"></a> [cidr\_vpc](#input\_cidr\_vpc) | cidr da VPC | `string` | n/a | yes |
| <a name="input_count_available_subnets"></a> [count\_available\_subnets](#input\_count\_available\_subnets) | Numero de Zonas de disponibilidade | `number` | n/a | yes |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | true ou false de acordo com a necessidade | `bool` | n/a | yes |
| <a name="input_nat-eip"></a> [nat-eip](#input\_nat-eip) | name para eip | `string` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | nat gateway name | `string` | n/a | yes |
| <a name="input_network_acl"></a> [network\_acl](#input\_network\_acl) | Regras de Network Acls AWS | `map(object({ protocol = string, action = string, cidr_blocks = string, from_port = number, to_port = number }))` | n/a | yes |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Tags adicionais | `any` | n/a | yes |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Tags adicionais | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Região na AWS | `string` | n/a | yes |
| <a name="input_route_table_tag"></a> [route\_table\_tag](#input\_route\_table\_tag) | Tag Name das route tables | `string` | n/a | yes |
| <a name="input_subnet_indices_for_nat"></a> [subnet\_indices\_for\_nat](#input\_subnet\_indices\_for\_nat) | Quantidade a ser criado de acordo com a necessidade fornecendo o indice da quantidade de subnets | `list(number)` | n/a | yes |
| <a name="input_tag_igw"></a> [tag\_igw](#input\_tag\_igw) | Tag Name do internet gateway | `string` | n/a | yes |
| <a name="input_tags_vpc"></a> [tags\_vpc](#input\_tags\_vpc) | Tags para VPC | `map(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Id da VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | ARN do Internet Gateway |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | ID do Internet Gateway |
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | Lisa de allocation ID de Elastic IPs criados para AWS NAT Gateway |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | ID do Nat Gateway |
| <a name="output_natgw_interface_ids"></a> [natgw\_interface\_ids](#output\_natgw\_interface\_ids) | ID da interface associada ao NAT Gateways |
| <a name="output_private_subnet"></a> [private\_subnet](#output\_private\_subnet) | IDs das subnets privadas |
| <a name="output_public_subnet"></a> [public\_subnet](#output\_public\_subnet) | IDs das subnets publicas |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | Idendificador da VPC |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN da VPC |
| <a name="output_vpc_cidrblock"></a> [vpc\_cidrblock](#output\_vpc\_cidrblock) | Range ip da VPC |
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_vpc"></a> [cidr\_vpc](#input\_cidr\_vpc) | cidr da VPC | `string` | n/a | yes |
| <a name="input_count_available_subnets"></a> [count\_available\_subnets](#input\_count\_available\_subnets) | Numero de Zonas de disponibilidade | `number` | n/a | yes |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | true ou false de acordo com a necessidade | `bool` | n/a | yes |
| <a name="input_nat-eip"></a> [nat-eip](#input\_nat-eip) | name para eip | `string` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | nat gateway name | `string` | n/a | yes |
| <a name="input_network_acl"></a> [network\_acl](#input\_network\_acl) | Regras de Network Acls AWS | `map(object({ protocol = string, action = string, cidr_blocks = string, from_port = number, to_port = number }))` | n/a | yes |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Tags adicionais | `any` | n/a | yes |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Tags adicionais | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Região na AWS | `string` | n/a | yes |
| <a name="input_route_table_tag"></a> [route\_table\_tag](#input\_route\_table\_tag) | Tag Name das route tables | `string` | n/a | yes |
| <a name="input_subnet_indices_for_nat"></a> [subnet\_indices\_for\_nat](#input\_subnet\_indices\_for\_nat) | Quantidade a ser criado de acordo com a necessidade fornecendo o indice da quantidade de subnets | `list(number)` | n/a | yes |
| <a name="input_tag_igw"></a> [tag\_igw](#input\_tag\_igw) | Tag Name do internet gateway | `string` | n/a | yes |
| <a name="input_tags_vpc"></a> [tags\_vpc](#input\_tags\_vpc) | Tags para VPC | `map(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Id da VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | ARN do Internet Gateway |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | ID do Internet Gateway |
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | Lisa de allocation ID de Elastic IPs criados para AWS NAT Gateway |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | ID do Nat Gateway |
| <a name="output_natgw_interface_ids"></a> [natgw\_interface\_ids](#output\_natgw\_interface\_ids) | ID da interface associada ao NAT Gateways |
| <a name="output_private_subnet"></a> [private\_subnet](#output\_private\_subnet) | IDs das subnets privadas |
| <a name="output_public_subnet"></a> [public\_subnet](#output\_public\_subnet) | IDs das subnets publicas |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | Idendificador da VPC |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN da VPC |
| <a name="output_vpc_cidrblock"></a> [vpc\_cidrblock](#output\_vpc\_cidrblock) | Range ip da VPC |
