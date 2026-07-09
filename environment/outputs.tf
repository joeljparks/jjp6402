output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "mongodb_private_ip" {
  value = module.mongodb.private_ip
}

output "mongodb_public_ip" {
  value = module.mongodb.public_ip
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "mongo_backup_bucket" {
  value = module.storage.mongo_backup_bucket_name
}

output "mongodb_admin_password" {
  value     = random_password.mongodb_admin.result
  sensitive = true
}

output "mongodb_app_password" {
  value     = random_password.mongodb_app.result
  sensitive = true
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "aws_load_balancer_controller_role_arn" {
  value = module.kubernetes_addons.aws_load_balancer_controller_role_arn
}

output "mongodb_app_connection_string" {
  value     = "mongodb://${urlencode(var.mongodb_app_user)}:${urlencode(random_password.mongodb_app.result)}@${module.mongodb.private_ip}:27017/${var.mongodb_app_database}?authSource=${var.mongodb_app_database}"
  sensitive = true
}

output "jwt_secret" {
  value     = random_password.jwt_secret.result
  sensitive = true
}
