variable "cluster_name" {
  type = string
}
variable "cluster_oidc_provider_arn" {
  type = string
}
variable "namespace" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_oidc_issuer_url" {
  type = string
}

variable "domain" {
  description = "Domínio gerenciado pelo ExternalDNS"
  type        = string
}