variable "name_prefix" { type = string }

resource "aws_signer_signing_profile" "container" {
  name        = "jjp6402_container"
  platform_id = "Notation-OCI-SHA384-ECDSA"
}

output "signing_profile_name" {
  value = aws_signer_signing_profile.container.name
}
