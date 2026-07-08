locals {
  common_tags = {
    Project   = var.name_prefix
    ManagedBy = "Terraform"
  }

  az = "${var.aws_region}a"
}
