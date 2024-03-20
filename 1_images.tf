# This file creates ECR repositories for Docker container images.
# Purpose: ECR repositories are used to store, manage, and deploy Docker container images. 
# They are essential for running containerized applications on AWS.

# Resource: aws_ecr_repository
# This resource creates an AWS ECR repository where you can push, pull, and manage Docker images.
# It's important for automating your CI/CD pipeline for containerized applications.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository

resource "aws_ecr_repository" "repo" {
  for_each = local.names["repository"]
  name                 = join("-",[local.prefix, "ecr", var.appname, var.environment, each.value])
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.ecr_cmk.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}