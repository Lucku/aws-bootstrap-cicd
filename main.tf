terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# Build an S3 Bucket and DynamoDB for Terraform state and locking
module "bootstrap" {
  source         = "./modules/bootstrap"
  project_name   = var.project_name
  application_id = var.application_id
  environment    = var.environment

  s3_tfstate_bucket_name            = "${var.application_id}-terraform-tfstate-bucket-${var.environment}"
  s3_logging_bucket_name            = "${var.application_id}-codebuild-logging-bucket-${var.environment}"
  dynamodb_state_locking_table_name = "${var.application_id}-codebuild-terraform-locking-table-${var.environment}"
  codebuild_iam_role_name           = "${var.application_id}-codebuild-role-${var.environment}"
  codebuild_iam_role_policy_name    = "${var.application_id}-codebuild-policy-${var.environment}"
  terraform_iam_role_name           = "${var.application_id}-terraform-role-${var.environment}"
  terraform_iam_role_policy_name    = "${var.application_id}-terraform-policy-${var.environment}"
  codecommit_repo_arn               = module.codecommit.codecommit_repo_arn
  codepipeline_artifact_bucket_arn  = module.codepipeline.codepipeline_artifact_bucket_arn
}

## Build a CodeCommit Git repository
module "codecommit" {
  source         = "./modules/codecommit"
  project_name   = var.project_name
  application_id = var.application_id
  environment    = var.environment

  repository_name = var.application_id
}

## Build CodeBuild projects for Build, Terraform Plan and Terraform Apply
module "codebuild" {
  source         = "./modules/codebuild"
  project_name   = var.project_name
  application_id = var.application_id
  environment    = var.environment

  codebuild_project_build_name           = "${var.application_id}-build-${var.environment}"
  codebuild_project_terraform_plan_name  = "${var.application_id}-terraform-plan-${var.environment}"
  codebuild_project_terraform_apply_name = "${var.application_id}-terraform-apply-${var.environment}"
  s3_tfstate_bucket_name                 = module.bootstrap.s3_tfstate_bucket
  dynamodb_state_locking_table_name      = module.bootstrap.dynamodb_state_locking_table
  s3_logging_bucket_id                   = module.bootstrap.s3_logging_bucket_id
  s3_logging_bucket_name                 = module.bootstrap.s3_logging_bucket
  codebuild_iam_role_arn                 = module.bootstrap.codebuild_iam_role_arn
}

## Build a CodePipeline
module "codepipeline" {
  source         = "./modules/codepipeline"
  project_name   = var.project_name
  application_id = var.application_id
  environment    = var.environment

  codepipeline_name                 = "${var.application_id}-pipeline-${var.environment}"
  codepipeline_artifact_bucket_name = "${var.application_id}-artifact-bucket-${var.environment}"
  codepipeline_role_name            = "${var.application_id}-codepipeline-role-${var.environment}"
  codepipeline_role_policy_name     = "${var.application_id}-codepipeline-policy-${var.environment}"
  codecommit_repo_name              = module.codecommit.codecommit_repo_name
  codecommit_branch_name            = var.branch_name
  codebuild_build_name              = module.codebuild.codebuild_build_name
  codebuild_tf_plan_name            = module.codebuild.codebuild_terraform_plan_name
  codebuild_tf_apply_name           = module.codebuild.codebuild_terraform_apply_name
}
