variable "project_name" {
  description = "Name of the business project"
}

variable "application_id" {
  description = "Name of the specific application"
}

variable "environment" {
  description = "Application environment (dev/prod)"
}

variable "codebuild_project_build_name" {
  description = "Name for CodeBuild Build Project"
}

variable "codebuild_project_terraform_plan_name" {
  description = "Name for CodeBuild Terraform Plan Project"
}

variable "codebuild_project_terraform_apply_name" {
  description = "Name for CodeBuild Terraform Apply Project"
}

variable "s3_tfstate_bucket_name" {
  description = "Name of the S3 bucket that holds the Terraform state"
}

variable "dynamodb_state_locking_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
}

variable "s3_logging_bucket_id" {
  description = "ID of the S3 bucket for access logging"
}

variable "s3_logging_bucket_name" {
  description = "Name of the S3 bucket for access logging"
}

variable "codebuild_iam_role_arn" {
  description = "ARN of the CodeBuild IAM role"
}
