variable "project_name" {
  description = "Name of the business project"
}

variable "application_id" {
  description = "Name of the specific application"
}

variable "environment" {
  description = "Application environment (dev/prod)"
}

variable "codepipeline_artifact_bucket_name" {
  description = "Name of the TF CodePipeline S3 bucket for artifacts"
}

variable "codepipeline_role_name" {
  description = "Name of the Terraform CodePipeline IAM Role"
}

variable "codepipeline_role_policy_name" {
  description = "Name of the Terraform IAM Role Policy"
}

variable "codepipeline_name" {
  description = "Terraform CodePipeline Name"
}

variable "codecommit_repo_name" {
  description = "Terraform CodeCommit repo name"
}

variable "codecommit_branch_name" {
  description = "Name of the branch in the CodeCommit repository to fetch from"
}

variable "codebuild_build_name" {
  description = "Build CodeBuild project name"
}

variable "codebuild_tf_plan_name" {
  description = "Terraform plan CodeBuild project name"
}

variable "codebuild_tf_apply_name" {
  description = "Terraform apply CodeBuild project name"
}
