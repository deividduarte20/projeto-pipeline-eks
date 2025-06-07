variable "cidr_vpc" {
  description = "cidr da VPC"
  type        = string
}

variable "region" {
  type        = string
  description = "Região na AWS"
}


variable "count_available_subnets" {
  type        = number
  description = "Numero de Zonas de disponibilidade"
}

variable "public_subnet_tags" {
  description = "Tags adicionais"
}

variable "private_subnet_tags" {
  description = "Tags adicionais"
}

variable "vpc" {
  type        = string
  description = "Id da VPC"
}


variable "tags_vpc" {
  description = "Tags para VPC"
  type        = map(string)
}


variable "tag_igw" {
  description = "Tag Name do internet gateway"
  type        = string
}


variable "route_table_tag" {
  description = "Tag Name das route tables"
  type        = string
}


variable "network_acl" {
  description = "Regras de Network Acls AWS"
  type        = map(object({ protocol = string, action = string, cidr_blocks = string, from_port = number, to_port = number }))
}

variable "create_nat_gateway" {
  type        = bool
  description = "true ou false de acordo com a necessidade"
}

variable "nat_gateway_name" {
  type        = string
  description = "nat gateway name"
}

variable "nat-eip" {
  type        = string
  description = "name para eip"
}

variable "subnet_indices_for_nat" {
  type        = list(number)
  description = "Quantidade a ser criado de acordo com a necessidade fornecendo o indice da quantidade de subnets"
}
