output "oidc_provider" {
  value       = module.cluster_eks.oidc_provider
  description = "Tls certificate do cluster EKS"
}

output "eks_cluster_name" {
  value       = module.cluster_eks.eks_cluster_name
  description = "Nome do cluster EKS"
}

output "oidc" {
  value       = module.cluster_eks.oidc
  description = "Url do OIDC do cluster EKS"
}


output "certificate_arn" {
  value       = aws_acm_certificate_validation.public.certificate_arn
  description = "ARN do certificado ACM usado pelos Ingresses"
}
