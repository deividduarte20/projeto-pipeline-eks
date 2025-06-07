provider "aws" {
  region = local.region
  default_tags {
    tags = {
      Projeto   = "devops-${local.project_name}"
      Terraform = "true"
    }
  }
}


provider "kubernetes" {
  host                   = module.cluster_eks.endpoint
  cluster_ca_certificate = base64decode(module.cluster_eks.certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.cluster_eks.endpoint
    cluster_ca_certificate = base64decode(module.cluster_eks.certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.eks_cluster_name]
      command     = "aws"
    }
  }
}


provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.cluster_eks.endpoint
  cluster_ca_certificate = base64decode(module.cluster_eks.certificate_authority)
  # token                  = module.cluster_eks.token
  load_config_file = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.eks_cluster_name]
  }
}

