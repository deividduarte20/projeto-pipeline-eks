resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-nodegroup"
  node_role_arn   = aws_iam_role.this.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "SPOT"
  version         = var.eks_version
  instance_types  = var.instance_types

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }


  depends_on = [
    aws_iam_role_policy_attachment.ecr_attach,
    aws_iam_role_policy_attachment.node_attach,
    aws_iam_role_policy_attachment.cni_attach
  ]
}