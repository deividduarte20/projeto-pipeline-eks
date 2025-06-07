module "network" {
  source                  = "./modules/network"
  region                  = local.region
  cidr_vpc                = local.cidr_vpc
  count_available_subnets = local.count_available_subnets
  vpc                     = module.network.vpc
  tag_igw                 = local.tag_igw
  route_table_tag         = local.route_table_tag
  network_acl             = local.network_acl
  create_nat_gateway      = local.create_nat_gateway
  nat_gateway_name        = local.nat_gateway_name
  nat-eip                 = local.nat-eip
  subnet_indices_for_nat  = local.subnet_indices_for_nat
  tags_vpc                = local.tags_vpc
  public_subnet_tags      = local.public_subnet_tags
  private_subnet_tags     = local.private_subnet_tags
}

module "cluster_eks" {
  source                  = "./modules/eks-cluster"
  project_name            = local.project_name
  subnet_ids              = module.network.public_subnet
  endpoint_private_access = local.endpoint_private_access
  endpoint_public_access  = local.endpoint_public_access
  eks_version             = local.eks_version
  cidr_vpc                = local.cidr_vpc

  depends_on = [
    module.network
  ]
}

module "node_group" {
  source         = "./modules/node-group"
  project_name   = local.project_name
  subnet_ids     = module.network.private_subnet
  cluster_name   = module.cluster_eks.eks_cluster_name
  eks_version    = local.eks_version
  instance_types = local.instance_types

  depends_on = [
    module.cluster_eks
  ]
}

module "aws-load-balancer-controller" {
  source       = "./modules/aws-loadbalancer-controller"
  project_name = local.project_name
  oidc         = module.cluster_eks.oidc
  cluster_name = module.cluster_eks.eks_cluster_name
  vpc_id       = module.network.vpc

  depends_on = [
    module.cluster_eks,
    module.node_group
  ]
}

module "karpenter" {
  source                            = "./modules/karpenter"
  project_name                      = local.project_name
  oidc                              = module.cluster_eks.oidc
  endpoint                          = module.cluster_eks.endpoint
  cluster_name                      = "${local.project_name}-cluster"
  cluster_security_group_id         = module.cluster_eks.cluster_security_group_id
  cluster_primary_security_group_id = module.cluster_eks.cluster_primary_security_group_id

  depends_on = [
    module.cluster_eks,
    module.node_group,
    module.aws-load-balancer-controller
  ]
}

module "externaldns" {
  source                    = "./modules/externaldns"
  cluster_name              = module.cluster_eks.eks_cluster_name
  cluster_oidc_provider_arn = module.cluster_eks.oidc_provider_arn
  cluster_oidc_issuer_url   = module.cluster_eks.oidc
  namespace                 = "externaldns"
  aws_region                = "us-east-1"
  domain                    = "dtechdevops.shop"

  depends_on = [
    module.cluster_eks
  ]
}

module "ebs_csi_driver" {
  source = "./modules/ebs-csi-driver"

  oidc_provider_arn = module.cluster_eks.oidc_provider_arn
  oidc_provider_url = module.cluster_eks.oidc

  depends_on = [
    module.cluster_eks
  ]
}