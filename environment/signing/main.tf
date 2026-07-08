variable "name_prefix" { type = string }

resource "aws_signer_signing_profile" "container" {
  name_prefix = "jjp6402_container_"
  platform_id = "Notation-OCI-SHA384-ECDSA"
}

output "signing_profile_name" {
  value = aws_signer_signing_profile.container.name
}
