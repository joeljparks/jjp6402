variable "name_prefix" { type = string }

resource "aws_codeartifact_domain" "this" {
  domain = var.name_prefix
}

resource "aws_codeartifact_repository" "generic" {
  repository = "${var.name_prefix}-generic"
  domain     = aws_codeartifact_domain.this.domain
}

resource "aws_codeartifact_repository" "go" {
  repository = "${var.name_prefix}-go"
  domain     = aws_codeartifact_domain.this.domain
}
