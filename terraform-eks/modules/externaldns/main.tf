resource "kubernetes_namespace" "externaldns" {
  metadata {
    name = var.namespace
  }
}

data "aws_iam_policy_document" "externaldns" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZonesByName",
      "route53:GetHostedZone",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "route53:GetChange"
    ]
    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_policy" "externaldns" {
  name   = "${var.cluster_name}-externaldns"
  policy = data.aws_iam_policy_document.externaldns.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:externaldns"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "externaldns" {
  name               = "${var.cluster_name}-externaldns"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "externaldns" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns.arn
}

resource "kubernetes_service_account" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns.arn
    }
  }
  depends_on = [kubernetes_namespace.externaldns]
}

resource "helm_release" "externaldns" {
  name       = "externaldns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.namespace

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "externaldns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.externaldns.arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "txtOwnerId"
    value = "externaldns"
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "logLevel"
    value = "debug"
  }

  depends_on = [
    kubernetes_service_account.externaldns,
    aws_iam_role_policy_attachment.externaldns
  ]
}