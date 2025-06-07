// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.tag_igw
  }

  lifecycle {
    create_before_destroy = true
  }
}
