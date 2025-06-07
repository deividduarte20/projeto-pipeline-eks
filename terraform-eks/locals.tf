locals {
  project_name            = "devops"
  region                  = "us-east-1"
  environment             = "homolog"
  endpoint_private_access = true
  endpoint_public_access  = true
  eks_version             = "1.32"
  instance_types          = ["m4.xlarge"]
  cidr_vpc                = "10.10.0.0/16"
  count_available_subnets = 2
  tag_igw                 = "igw-${local.project_name}"
  route_table_tag         = "rt-${local.project_name}"
  create_nat_gateway      = true
  subnet_indices_for_nat  = range(local.count_available_subnets)
  nat_gateway_name        = "natgw-${local.project_name}"
  nat-eip                 = "eip-${local.project_name}"
  aws_region              = "us-east-1"


  network_acl = {
    100 = { protocol = "tcp", action = "allow", cidr_blocks = "0.0.0.0/0", from_port = 22, to_port = 22 }
    105 = { protocol = "tcp", action = "allow", cidr_blocks = "0.0.0.0/0", from_port = 80, to_port = 80 }
    110 = { protocol = "tcp", action = "allow", cidr_blocks = "0.0.0.0/0", from_port = 443, to_port = 443 }
    150 = { protocol = "tcp", action = "allow", cidr_blocks = "0.0.0.0/0", from_port = 1024, to_port = 65535 }
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.project_name}-cluster" = "owned"
    "kubernetes.io/role/elb"                              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.project_name}-cluster" = "owned"
    "kubernetes.io/role/internal-elb"                     = "1"
    "karpenter.sh/discovery"                              = "${local.project_name}-cluster"
  }

  tags_vpc = {
    Name        = "${local.project_name}-vpc"
    Environment = "${local.environment}"
  }
}

