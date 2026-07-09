resource "random_password" "mongodb_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "mongodb_app" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

module "network" {
  source              = "./networking"
  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  secondary_vpc_cidr  = var.secondary_vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = local.az
}

module "iam" {
  source      = "./iam"
  name_prefix = var.name_prefix
}

module "storage" {
  source      = "./storage"
  name_prefix = var.name_prefix
}

module "ecr" {
  source      = "./ecr"
  name_prefix = var.name_prefix
}

module "eks" {
  source                   = "./eks"
  name_prefix              = var.name_prefix
  eks_version              = var.eks_version
  private_subnet_ids       = [module.network.private_subnet_id]
  cluster_role_arn         = module.iam.eks_cluster_role_arn
  node_role_arn            = module.iam.eks_node_role_arn
  vpc_cni_addon_version    = "v1.22.2-eksbuild.1"
  kube_proxy_addon_version = "v1.36.0-eksbuild.9"
  coredns_addon_version    = "v1.14.3-eksbuild.3"
}

module "mongodb" {
  source                = "./ec2-mongodb"
  name_prefix           = var.name_prefix
  subnet_id             = module.network.public_subnet_id
  vpc_id                = module.network.vpc_id
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  eks_security_group_id = module.eks.cluster_security_group_id
  instance_profile_name = module.iam.mongodb_instance_profile_name
  backup_bucket_name    = module.storage.mongo_backup_bucket_name
  mongodb_version       = var.mongodb_version
  admin_user            = var.mongodb_admin_user
  admin_password        = random_password.mongodb_admin.result
  app_user              = var.mongodb_app_user
  app_password          = random_password.mongodb_app.result
  app_database          = var.mongodb_app_database
}

module "security" {
  source                 = "./security-controls"
  name_prefix            = var.name_prefix
  cloudtrail_bucket_name = module.storage.cloudtrail_bucket_name
  config_bucket_name     = module.storage.config_bucket_name
  config_role_arn        = module.iam.config_role_arn

  depends_on = [module.storage, module.iam]
}

module "codeartifact" {
  source      = "./codeartifact"
  name_prefix = var.name_prefix
}

module "codedeploy" {
  source           = "./codedeploy"
  name_prefix      = var.name_prefix
  service_role_arn = module.iam.codedeploy_role_arn
}

module "signing" {
  source      = "./signing"
  name_prefix = var.name_prefix
}

module "kubernetes_addons" {
  source                       = "./kubernetes-addons"
  name_prefix                  = var.name_prefix
  aws_region                   = var.aws_region
  vpc_id                       = module.network.vpc_id
  eks_cluster_name             = module.eks.cluster_name
  eks_oidc_provider_arn        = module.eks.oidc_provider_arn
  eks_oidc_provider_url        = module.eks.oidc_provider_url
  aws_load_balancer_policy_arn = module.iam.aws_load_balancer_controller_policy_arn

  depends_on = [module.eks]
}

resource "kubernetes_namespace_v1" "tasky" {
  metadata {
    name = "tasky"
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret_v1" "mongodb_app" {
  metadata {
    name      = "${var.name_prefix}-mongodb-app"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
  }

  data = {
    MONGODB_URL = "mongodb://${urlencode(var.mongodb_app_user)}:${urlencode(random_password.mongodb_app.result)}@${module.mongodb.private_ip}:27017/${var.mongodb_app_database}?authSource=${var.mongodb_app_database}"
    SECRET_KEY  = random_password.jwt_secret.result
  }

  type = "Opaque"

  depends_on = [module.eks, module.mongodb]
}
