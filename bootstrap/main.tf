resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.name_prefix}-terraform"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "${var.name_prefix}-codepipeline-artifacts-${var.aws_account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_codeconnections_connection" "github" {
  name          = "${var.name_prefix}-github"
  provider_type = "GitHub"
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.name_prefix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["logs:*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:*"], Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
      ]},
      {
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]
        Resource = [
          aws_codeconnections_connection.github.arn,
          replace(aws_codeconnections_connection.github.arn, ":codeconnections:", ":codestar-connections:")
        ]
      },
      { Effect = "Allow", Action = [
          "ecr:*", "eks:*", "ec2:*", "elasticloadbalancing:*", "iam:*",
          "s3:*", "cloudtrail:*", "config:*", "access-analyzer:*",
          "codeartifact:*", "codedeploy:*", "signer:*",
          "ssm:GetParameter", "ssm:GetParameters", "ssm:PutParameter",
          "ssm:DeleteParameter", "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource",
          "ssm:ListTagsForResource", "sts:*"
      ], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:*"], Resource = [
        aws_s3_bucket.pipeline_artifacts.arn,
        "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      ]},
      { Effect = "Allow", Action = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codeconnections:UseConnection"], Resource = "*" }
    ]
  })
}

locals {
  codebuild_common_env = [
    { name = "AWS_ACCOUNT_ID", value = var.aws_account_id },
    { name = "AWS_REGION", value = var.aws_region }
  ]
}

resource "aws_codebuild_project" "environment" {
  name          = "${var.name_prefix}-environment"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 60

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    dynamic "environment_variable" {
      for_each = local.codebuild_common_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/codebuild-environment.yml"
  }
}

resource "aws_codebuild_project" "app_build" {
  name          = "${var.name_prefix}-app-build"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 60

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = local.codebuild_common_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/codebuild-app-build.yml"
  }
}

resource "aws_codebuild_project" "app_deploy" {
  name          = "${var.name_prefix}-app-deploy"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    dynamic "environment_variable" {
      for_each = local.codebuild_common_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/codebuild-app-deploy.yml"
  }
}

resource "aws_codebuild_project" "app_validate" {
  name          = "${var.name_prefix}-app-validate"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:8.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    dynamic "environment_variable" {
      for_each = local.codebuild_common_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/codebuild-app-validate.yml"
  }
}

resource "aws_codepipeline" "environment" {
  name     = "${var.name_prefix}-environment"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn        = aws_codeconnections_connection.github.arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
        DetectChanges        = "true"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Environment"
    action {
      name             = "Terraform"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["environment_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.environment.name
      }
    }
  }
}

resource "aws_codepipeline" "application" {
  name     = "${var.name_prefix}-application"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn        = aws_codeconnections_connection.github.arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
        DetectChanges        = "true"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildScanSign"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = { ProjectName = aws_codebuild_project.app_build.name }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "VerifyAndDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output", "build_output"]
      output_artifacts = ["deploy_output"]
      version          = "1"
      configuration = {
        ProjectName   = aws_codebuild_project.app_deploy.name
        PrimarySource = "source_output"
      }
    }
  }

  stage {
    name = "Validate"
    action {
      name            = "Validate"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output", "build_output"]
      version         = "1"
      configuration = {
        ProjectName   = aws_codebuild_project.app_validate.name
        PrimarySource = "source_output"
      }
    }
  }
}
