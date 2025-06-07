variable "project_name" {
  type        = string
  description = "Nome do projeto"
}

variable "oidc" {
  type        = string
  description = "ID do OIDC provider"
}

variable "cluster_name" {
  type        = string
  description = "Nome do cluster"
}

variable "vpc_id" {
  type        = string
  description = "Id da VPC"
}
