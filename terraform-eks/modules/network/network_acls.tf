#Network Acl
# Acl Public
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc
  subnet_ids = aws_subnet.public.*.id

  dynamic "egress" {
    for_each = var.network_acl
    content {
      protocol   = egress.value["protocol"]
      rule_no    = egress.key
      action     = egress.value["action"]
      cidr_block = egress.value["cidr_blocks"]
      from_port  = egress.value["from_port"]
      to_port    = egress.value["to_port"]
    }
  }

  dynamic "ingress" {
    for_each = var.network_acl
    content {
      protocol   = ingress.value["protocol"]
      rule_no    = ingress.key
      action     = ingress.value["action"]
      cidr_block = ingress.value["cidr_blocks"]
      from_port  = ingress.value["from_port"]
      to_port    = ingress.value["to_port"]
    }
  }

  tags = {
    Name = "ACL-Public"
  }
}

#Network Acl
# Acl Private
resource "aws_network_acl" "private" {
  vpc_id     = var.vpc
  subnet_ids = aws_subnet.private.*.id

  dynamic "egress" {
    for_each = var.network_acl
    content {
      protocol   = egress.value["protocol"]
      rule_no    = egress.key
      action     = egress.value["action"]
      cidr_block = egress.value["cidr_blocks"]
      from_port  = egress.value["from_port"]
      to_port    = egress.value["to_port"]
    }
  }

  dynamic "ingress" {
    for_each = var.network_acl
    content {
      protocol   = ingress.value["protocol"]
      rule_no    = ingress.key
      action     = ingress.value["action"]
      cidr_block = ingress.value["cidr_blocks"]
      from_port  = ingress.value["from_port"]
      to_port    = ingress.value["to_port"]
    }
  }

  tags = {
    Name = "ACL-Private"
  }
}