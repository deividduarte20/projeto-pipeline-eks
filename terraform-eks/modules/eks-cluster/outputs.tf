output "endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "Endpoint do cluster EKS"
}

output "certificate_authority" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "CA do cluster EKS"
}

output "eks_vpc_config" {
  value       = aws_eks_cluster.this.vpc_config
  description = "Configuracoes de vpc, subnets do EKS"
}

output "oidc_provider" {
  value       = data.tls_certificate.this.certificates[0].sha1_fingerprint
  description = "Tls certificate do cluster EKS"
}

output "eks_cluster_name" {
  value       = aws_eks_cluster.this.id
  description = "Nome do cluster EKS"
}

output "oidc" {
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  description = "Url do OIDC do cluster EKS"
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "The ID of the EKS cluster primary security group"
  value = try(
    tolist(aws_eks_cluster.this.vpc_config[0].security_group_ids)[0],
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    ""
  )
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.this.arn
  description = "ARN do OIDC provider do cluster EKS"
}