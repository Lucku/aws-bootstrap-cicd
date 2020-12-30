# Build S3 bucket for CodePipeline artifact storage
resource "aws_s3_bucket" "tf_codepipeline_artifact_bucket" {
  bucket = var.codepipeline_artifact_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

output "codepipeline_artifact_bucket_arn" {
  value = aws_s3_bucket.tf_codepipeline_artifact_bucket.arn
}

resource "aws_iam_role" "tf_codepipeline_role" {
  name = var.codepipeline_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "tf_codepipeline_policy" {
  name = var.codepipeline_role_policy_name
  role = aws_iam_role.tf_codepipeline_role.id

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Condition": {
        "StringEqualsIfExists": {
          "iam:PassedToService": [
            "cloudformation.amazonaws.com",
            "elasticbeanstalk.amazonaws.com",
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    },
    {
      "Action": [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "elasticbeanstalk:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "s3:*",
        "sns:*",
        "cloudformation:*",
        "rds:*",
        "sqs:*",
        "ecs:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "lambda:InvokeFunction",
        "lambda:ListFunctions"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "opsworks:CreateDeployment",
        "opsworks:DescribeApps",
        "opsworks:DescribeCommands",
        "opsworks:DescribeDeployments",
        "opsworks:DescribeInstances",
        "opsworks:DescribeStacks",
        "opsworks:UpdateApp",
        "opsworks:UpdateStack"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:UpdateStack",
        "cloudformation:CreateChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:SetStackPolicy",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "devicefarm:ListProjects",
        "devicefarm:ListDevicePools",
        "devicefarm:GetRun",
        "devicefarm:GetUpload",
        "devicefarm:CreateUpload",
        "devicefarm:ScheduleRun"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "servicecatalog:ListProvisioningArtifacts",
        "servicecatalog:CreateProvisioningArtifact",
        "servicecatalog:DescribeProvisioningArtifact",
        "servicecatalog:DeleteProvisioningArtifact",
        "servicecatalog:UpdateProduct"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
EOF
}

resource "aws_codepipeline" "tf_codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.tf_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.tf_codepipeline_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = var.codecommit_repo_name
        BranchName     = var.codecommit_branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      version          = "1"
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = var.codebuild_build_name
      }
    }

  }

  stage {
    name = "Deploy"

    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["BuildArtifact"]
      version          = "1"
      output_artifacts = ["PlanArtifact"]
      run_order        = 1

      configuration = {
        ProjectName = var.codebuild_tf_plan_name
      }
    }

    action {
      name      = "ManualApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 2

      configuration = {
        ExternalEntityLink = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.tf_codepipeline_artifact_bucket.bucket}"
      }
    }

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["PlanArtifact"]
      version         = "1"
      run_order       = 3

      configuration = {
        ProjectName = var.codebuild_tf_apply_name
      }
    }
  }

  tags = {
    Name          = var.codepipeline_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
    CreatedDate   = timestamp()
  }
}
