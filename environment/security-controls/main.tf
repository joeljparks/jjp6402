variable "name_prefix" { type = string }
variable "cloudtrail_bucket_name" { type = string }
variable "config_bucket_name" { type = string }
variable "config_role_arn" { type = string }

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-cloudtrail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name_prefix}-config-recorder"
  role_arn = var.config_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.name_prefix}-config-channel"
  s3_bucket_name = var.config_bucket_name
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "${var.name_prefix}-access-analyzer"
  type          = "ACCOUNT"
}
