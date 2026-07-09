variable "name_prefix" { type = string }

resource "aws_signer_signing_profile" "container" {
  name_prefix = "${var.name_prefix}_container_"
  platform_id = "Notation-OCI-SHA384-ECDSA"
}

resource "aws_ssm_parameter" "signing_profile_name" {
  name        = "/${var.name_prefix}/signing-profile-name"
  description = "AWS Signer signing profile name for ${var.name_prefix} container images."
  type        = "String"
  value       = aws_signer_signing_profile.container.name

  tags = {
    Project   = var.name_prefix
    ManagedBy = "Terraform"
  }
}

output "signing_profile_name" {
  value = aws_signer_signing_profile.container.name
}

output "signing_profile_parameter_name" {
  value = aws_ssm_parameter.signing_profile_name.name
}
