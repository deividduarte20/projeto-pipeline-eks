terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
  }
  # backend "s3" {
  #   bucket = "projeto-eks-s3"
  #   key    = "dev/terrafrorm.tfstate"
  #   region = "us-east-1"
  # }
}