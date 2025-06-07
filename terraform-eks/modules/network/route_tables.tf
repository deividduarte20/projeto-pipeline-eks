// Route Tables
resource "aws_route_table" "public" {
  vpc_id = var.vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-${var.route_table_tag}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc

  count = var.create_nat_gateway ? length(var.subnet_indices_for_nat) : 1
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.create_nat_gateway ? element(aws_nat_gateway.nat_gateway.*.id, count.index) : null
    gateway_id     = var.create_nat_gateway ? null : aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.create_nat_gateway ? "${var.route_table_tag}-nat-${count.index + 1}" : "Private-${var.route_table_tag}"
  }
}

// Route Table association
resource "aws_route_table_association" "public" {
  count          = var.count_available_subnets
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}


resource "aws_route_table_association" "private" {
  count          = var.count_available_subnets
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, 0)
}
