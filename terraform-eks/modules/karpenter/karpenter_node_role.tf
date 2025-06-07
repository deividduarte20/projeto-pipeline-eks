resource "aws_iam_role" "karpenterNodeRole" {
  name = "${var.project_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-karpenter-node-role"
  }

}

resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.karpenterNodeRole.name
  policy_arn = data.aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_attach" {
  role       = aws_iam_role.karpenterNodeRole.name
  policy_arn = data.aws_iam_policy.node_policy.arn
}

resource "aws_iam_role_policy_attachment" "cni_attach" {
  role       = aws_iam_role.karpenterNodeRole.name
  policy_arn = data.aws_iam_policy.cni_policy.arn
}

resource "aws_iam_role_policy_attachment" "amazon_ssmmanaged_instance_core" {
  role       = aws_iam_role.karpenterNodeRole.name
  policy_arn = data.aws_iam_policy.amazon_ssmmanaged_instance_core.arn
}


