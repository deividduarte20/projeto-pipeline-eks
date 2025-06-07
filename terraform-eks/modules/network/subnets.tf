// Subnets públicas e privadas

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  count_azs = length(data.aws_availability_zones.available.names)
}

resource "aws_subnet" "private" {
  count             = var.count_available_subnets
  cidr_block        = cidrsubnet(var.cidr_vpc, 8, (count.index + 1))
  availability_zone = data.aws_availability_zones.available.names[count.index % local.count_azs]
  vpc_id            = var.vpc

  tags = merge(var.private_subnet_tags, {
    Name = "Private-${count.index + 1}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public" {
  count                   = var.count_available_subnets
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, var.count_available_subnets + (count.index + 1))
  availability_zone       = data.aws_availability_zones.available.names[count.index % local.count_azs]
  vpc_id                  = var.vpc
  map_public_ip_on_launch = true

  tags = merge(var.public_subnet_tags, {
    Name = "Public-${count.index + 1}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

