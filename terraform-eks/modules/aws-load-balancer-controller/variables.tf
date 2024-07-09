variable "project_name" {
  type        = string
  description = "Project Name to be used in Tags"
}

variable "tags" {
  type        = map(any)
  description = "Tags to be added to AWS resources"
}

variable "oidc" {
  type        = string
  description = "HTTPS URL from OIDC Provider of the EKS cluster"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}