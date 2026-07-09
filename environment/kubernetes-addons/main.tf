variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "eks_cluster_name" { type = string }
variable "eks_oidc_provider_arn" { type = string }
variable "eks_oidc_provider_url" { type = string }
variable "aws_load_balancer_policy_arn" { type = string }

data "aws_iam_policy_document" "lbc_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.name_prefix}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume.json
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = var.aws_load_balancer_policy_arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.lbc.arn
}
