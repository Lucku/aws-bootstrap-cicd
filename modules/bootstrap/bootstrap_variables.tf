variable "project_name" {
  description = "Name of the business project"
}

variable "application_id" {
  description = "Name of the specific application"
}

variable "environment" {
  description = "Application environment (dev/prod)"
}

variable "s3_tfstate_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state storage"
}

variable "s3_logging_bucket_name" {
  description = "Name of S3 bucket to use for access logging"
}

variable "dynamodb_state_locking_table_name" {
  description = "Name of DynamoDB table used for Terraform locking"
}

variable "codebuild_iam_role_name" {
  description = "Name for IAM Role utilized by CodeBuild"
}

variable "codebuild_iam_role_policy_name" {
  description = "Name for IAM policy used by CodeBuild"
}

variable "terraform_iam_role_name" {
  description = "Name for the IAM role utilized by Terraform"
}

variable "terraform_iam_role_policy_name" {
  description = "Name of the IAM policy used by Terraform"
}

variable "codecommit_repo_arn" {
  description = "Terraform CodeCommit Git repo ARN"
}

variable "codepipeline_artifact_bucket_arn" {
  description = "Codepipeline artifact bucket ARN"
}
