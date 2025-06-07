variable "project_name" {
  type        = string
  description = "Nome do projeto"
}


variable "subnet_ids" {
  type        = list(string)
  description = "Ids das subnets"
}

variable "endpoint_private_access" {
  type        = bool
  description = "Endpoint private habilitado"
}

variable "endpoint_public_access" {
  type        = bool
  description = "Endpoint public habilitado"
}

variable "eks_version" {
  type        = string
  description = "Versão do Kubernetes"
}

variable "cidr_vpc" {

}