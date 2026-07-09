locals {
  common_tags = {
    Project   = var.name_prefix
    ManagedBy = "Terraform"
  }

  az_a = "${var.aws_region}a"
  az_b = "${var.aws_region}b"
}
