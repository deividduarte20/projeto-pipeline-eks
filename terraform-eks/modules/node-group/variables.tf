variable "project_name" {
  type        = string
  description = "Nome do projeto"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Id das subnets privadas"
}

variable "cluster_name" {
  type        = string
  description = "Nome do cluster"
}


variable "eks_version" {
  type        = string
  description = "Versão do Kubernetes"
}

variable "instance_types" {
  type        = list(string)
  description = "Tipo da instancia"
}
