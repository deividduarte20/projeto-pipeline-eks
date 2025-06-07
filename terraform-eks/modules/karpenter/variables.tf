variable "cluster_name" {
  type        = string
  description = "Nome do cluster"
}

# variable "aws_iam_role_node" {

# }


variable "project_name" {
  type        = string
  description = "Nome do projeto"
}

variable "oidc" {
  type        = string
  description = "ID do OIDC provider"
}

variable "endpoint" {

}

variable "cluster_security_group_id" {
  type        = string
  description = "Security group ID of the EKS cluster"
}

variable "cluster_primary_security_group_id" {
  type        = string
  description = "The ID of the EKS cluster primary security group"
}
