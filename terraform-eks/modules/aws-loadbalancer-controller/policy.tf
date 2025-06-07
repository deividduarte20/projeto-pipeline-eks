resource "aws_iam_policy" "this" {
  name        = "${var.project_name}-aws-load-balancer-controller"
  description = "Policy para aws-load-balancer-controller"
  policy      = file("${path.module}/iam_policy.json")

  tags = {
    Name = "${var.project_name}-loadbalancer-controller"
  }
}