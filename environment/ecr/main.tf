variable "name_prefix" { type = string }

resource "aws_ecr_repository" "tasky" {
  name                 = "${var.name_prefix}-tasky-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" { value = aws_ecr_repository.tasky.repository_url }
output "repository_name" { value = aws_ecr_repository.tasky.name }
