data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

data "aws_ecrpublic_authorization_token" "token" {
  #   provider = aws.virginia
}

data "aws_iam_policy" "ecr_policy" {
  name = "AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "node_policy" {
  name = "AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "cni_policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "amazon_ssmmanaged_instance_core" {
  name = "AmazonSSMManagedInstanceCore"
}


