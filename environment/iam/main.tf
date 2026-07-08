variable "name_prefix" { type = string }

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  name               = "${var.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "mongodb" {
  name               = "${var.name_prefix}-mongodb-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.name_prefix}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

resource "aws_iam_role_policy" "mongodb_permissive" {
  name = "${var.name_prefix}-mongodb-permissive-policy"
  role = aws_iam_role.mongodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:*", "ec2:RunInstances", "ec2:CreateTags", "ec2:Describe*"], Resource = "*" }
    ]
  })
}

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  name               = "${var.name_prefix}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.name_prefix}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.name_prefix}-aws-lbc-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = [
          "elasticloadbalancing:*", "ec2:Describe*", "ec2:CreateSecurityGroup",
          "ec2:CreateTags", "ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress",
          "iam:CreateServiceLinkedRole", "acm:ListCertificates", "acm:DescribeCertificate",
          "wafv2:GetWebACL", "wafv2:GetWebACLForResource", "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL", "shield:GetSubscriptionState", "shield:DescribeProtection",
          "shield:CreateProtection", "shield:DeleteProtection"
        ], Resource = "*" }
    ]
  })
}

output "eks_cluster_role_arn" { value = aws_iam_role.eks_cluster.arn }
output "eks_node_role_arn" { value = aws_iam_role.eks_node.arn }
output "mongodb_instance_profile_name" { value = aws_iam_instance_profile.mongodb.name }
output "config_role_arn" { value = aws_iam_role.config.arn }
output "codedeploy_role_arn" { value = aws_iam_role.codedeploy.arn }
output "aws_load_balancer_controller_policy_arn" { value = aws_iam_policy.aws_load_balancer_controller.arn }
