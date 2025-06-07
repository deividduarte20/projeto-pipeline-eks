resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat(
        yamldecode(data.kubernetes_config_map_v1.aws_auth.data.mapRoles),
        [
          {
            rolearn  = aws_iam_role.karpenterNodeRole.arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          }
        ]
      )
    )
  }

  force = true

  depends_on = [
    helm_release.karpenter
  ]
}

data "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}