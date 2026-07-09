variable "name_prefix" {
  type = string
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "mongo_backup" {
  bucket        = "${var.name_prefix}-mongo5-backup"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "mongo_backup" {
  bucket                  = aws_s3_bucket.mongo_backup.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "mongo_backup" {
  bucket = aws_s3_bucket.mongo_backup.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "mongo_backup_public" {
  bucket     = aws_s3_bucket.mongo_backup.id
  policy     = data.aws_iam_policy_document.mongo_backup_public.json
  depends_on = [aws_s3_bucket_public_access_block.mongo_backup]
}

data "aws_iam_policy_document" "mongo_backup_public" {
  statement {
    sid     = "PublicList"
    effect  = "Allow"
    actions = ["s3:ListBucket"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [aws_s3_bucket.mongo_backup.arn]
  }

  statement {
    sid     = "PublicRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.mongo_backup.arn}/*"]
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.name_prefix}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = [aws_s3_bucket.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-cloudtrail"]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-cloudtrail"]
    }
  }
}

resource "aws_s3_bucket" "config" {
  bucket        = "${var.name_prefix}-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config.json
}

data "aws_iam_policy_document" "config" {
  statement {
    sid     = "AWSConfigBucketPermissionsCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = [aws_s3_bucket.config.arn]
  }

  statement {
    sid     = "AWSConfigBucketExistenceCheck"
    effect  = "Allow"
    actions = ["s3:ListBucket"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = [aws_s3_bucket.config.arn]
  }

  statement {
    sid     = "AWSConfigBucketDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.config.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

output "mongo_backup_bucket_name" {
  value = aws_s3_bucket.mongo_backup.bucket
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "config_bucket_name" {
  value = aws_s3_bucket.config.bucket
}
