output "github_connection_arn" {
  value = aws_codeconnections_connection.github.arn
}

output "github_connection_status" {
  value = aws_codeconnections_connection.github.connection_status
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "pipeline_artifact_bucket" {
  value = aws_s3_bucket.pipeline_artifacts.bucket
}

output "environment_pipeline" {
  value = aws_codepipeline.environment.name
}

output "application_pipeline" {
  value = aws_codepipeline.application.name
}
