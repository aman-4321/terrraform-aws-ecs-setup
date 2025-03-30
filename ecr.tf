# ECR Repository
resource "aws_ecr_repository" "nginx_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repository_name
  }
}

# ECR Lifecycle Policy to limit image count and remove untagged images
resource "aws_ecr_lifecycle_policy" "nginx_repo_policy" {
  repository = aws_ecr_repository.nginx_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only latest 5 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
} 
