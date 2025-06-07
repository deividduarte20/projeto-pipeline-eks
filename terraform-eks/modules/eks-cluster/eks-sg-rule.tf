resource "aws_security_group_rule" "this" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id

}

# resource "aws_security_group_rule" "api_ingress" {
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = [var.cidr_vpc]
#   security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
# }

# resource "aws_security_group_rule" "node_to_cluster" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
#   security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
# }