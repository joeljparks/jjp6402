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
