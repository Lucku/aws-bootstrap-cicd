resource "aws_codebuild_project" "codebuild_project_build" {
  name          = var.codebuild_project_build_name
  description   = "CodeBuild project created by Terraform"
  build_timeout = "5"
  service_role  = var.codebuild_iam_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = var.s3_logging_bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = "0.14.3"
    }
  }

  logs_config {

    s3_logs {
      status = "DISABLED"
      # location = "${var.s3_logging_bucket_id}/${var.codebuild_project_build_name}/build_log" (uncomment if desired to log in S3)
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name          = var.codebuild_project_build_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
    CreatedDate   = timestamp()
  }
}

# Output Build CodeBuild name to main.tf
output "codebuild_build_name" {
  value = var.codebuild_project_build_name
}

resource "aws_codebuild_project" "codebuild_project_terraform_plan" {
  name          = var.codebuild_project_terraform_plan_name
  description   = "CodeBuild project created by Terraform"
  build_timeout = "5"
  service_role  = var.codebuild_iam_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = var.s3_logging_bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = "0.14.3"
    }

    environment_variable {
      name  = "APPLICATION_ID"
      value = var.application_id
    }

    environment_variable {
      name  = "STATE_BUCKET_NAME"
      value = var.s3_tfstate_bucket_name
    }

    environment_variable {
      name  = "STATE_LOCKING_TABLE_NAME"
      value = var.dynamodb_state_locking_table_name
    }
  }

  logs_config {

    s3_logs {
      status = "DISABLED"
      #location = "${var.s3_logging_bucket_id}/${var.codebuild_project_terraform_plan_name}/build_log"
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec_tf_plan.yml")
  }

  tags = {
    Name          = var.codebuild_project_terraform_plan_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
    CreatedDate   = timestamp()
  }
}

# Output TF Plan CodeBuild name to main.tf
output "codebuild_terraform_plan_name" {
  value = var.codebuild_project_terraform_plan_name
}

resource "aws_codebuild_project" "codebuild_project_terraform_apply" {
  name          = var.codebuild_project_terraform_apply_name
  description   = "CodeBuild project created by Terraform"
  build_timeout = "5"
  service_role  = var.codebuild_iam_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = var.s3_logging_bucket_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = "0.14.3"
    }

    environment_variable {
      name  = "APPLICATION_ID"
      value = var.application_id
    }

    environment_variable {
      name  = "STATE_BUCKET_NAME"
      value = var.s3_tfstate_bucket_name
    }

    environment_variable {
      name  = "STATE_LOCKING_TABLE_NAME"
      value = var.dynamodb_state_locking_table_name
    }
  }

  logs_config {

    s3_logs {
      status = "DISABLED"
      #location = "${var.s3_logging_bucket_id}/${var.codebuild_project_terraform_apply_name}/build_log"
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec_tf_apply.yml")
  }

  tags = {
    Name          = var.codebuild_project_terraform_apply_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
    CreatedDate   = timestamp()
  }
}

# Output TF Apply CodeBuild name to main.tf
output "codebuild_terraform_apply_name" {
  value = var.codebuild_project_terraform_apply_name
}
