variable "name_prefix" { type = string }
variable "service_role_arn" { type = string }

resource "aws_codedeploy_app" "mongodb" {
  compute_platform = "Server"
  name             = "${var.name_prefix}-mongodb"
}

resource "aws_codedeploy_deployment_group" "mongodb" {
  app_name              = aws_codedeploy_app.mongodb.name
  deployment_group_name = "${var.name_prefix}-mongodb"
  service_role_arn      = var.service_role_arn

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "${var.name_prefix}-mongodb-vm"
  }
}
