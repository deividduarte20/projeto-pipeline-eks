locals {
  oidc = split("/", var.oidc)[4]
}

resource "aws_iam_role" "this" {
  name = "karpenter-controller"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/oidc.eks.${data.aws_region.this.name}.amazonaws.com/id/${local.oidc}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${data.aws_region.this.name}.amazonaws.com/id/${local.oidc}:sub": "system:serviceaccount:karpenter:karpenter",
                    "oidc.eks.${data.aws_region.this.name}.amazonaws.com/id/${local.oidc}:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF

  tags = {
    Name = "${var.project_name}-karpenter-controller"
  }

}


resource "aws_iam_policy" "this" {
  name   = "KarpenterController"
  policy = file("${path.module}/controller-trust-policy.json")
}


resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}


resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = aws_iam_role.karpenterNodeRole.name
  # role = var.aws_iam_role_node
}