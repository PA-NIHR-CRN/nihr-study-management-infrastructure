resource "aws_ecr_repository" "repo" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = var.repo_name
    Environment = var.env
    System      = var.app
  }
  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }
}