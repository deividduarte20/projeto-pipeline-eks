resource "aws_nat_gateway" "nat_gateway" {
  count = var.create_nat_gateway ? length(var.subnet_indices_for_nat) : 0

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = element(aws_subnet.public[*].id, var.subnet_indices_for_nat[count.index])

  tags = {
    Name = "${var.nat_gateway_name}-${count.index + 1}"
  }
}

resource "aws_eip" "nat_eip" {
  count  = var.create_nat_gateway ? length(var.subnet_indices_for_nat) : 0
  domain = "vpc"

  tags = {
    Name = "${var.nat-eip}-${count.index + 1}"
  }
}



