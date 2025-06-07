// Aws vpc

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags_vpc

  lifecycle {
    create_before_destroy = true
  }
}