provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_eks_cluster" "selected" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "selected" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.selected.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.selected.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.selected.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.selected.token
  }
}
