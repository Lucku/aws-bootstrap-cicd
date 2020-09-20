# Build AWS CodeCommit Git repository
resource "aws_codecommit_repository" "repo" {
  repository_name = var.repository_name
  description     = "CodeCommit repository created by Terraform"

  tags = {
    Name          = var.repository_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
    CreatedDate   = timestamp()
  }
}

# Output the repo info back to main.tf
output "codecommit_repo_arn" {
  value = aws_codecommit_repository.repo.arn
}

output "codecommit_repo_name" {
  value = var.repository_name
}
