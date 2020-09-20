# Build an S3 bucket to store TF state
resource "aws_s3_bucket" "state_bucket" {
  bucket = var.s3_tfstate_bucket_name

  # Tells AWS to encrypt the S3 bucket at rest by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Tells AWS to keep a version history of the state file
  versioning {
    enabled = true
  }

  tags = {
    Name          = var.s3_tfstate_bucket_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
  }
}

output "s3_tfstate_bucket" {
  value = aws_s3_bucket.state_bucket.bucket
}

# Build a DynamoDB to use for terraform state locking
resource "aws_dynamodb_table" "tf_lock_state" {
  name = var.dynamodb_state_locking_table_name

  # Pay per request is cheaper for low-i/o applications, like our TF lock state
  billing_mode = "PAY_PER_REQUEST"

  # Hash key is required, and must be an attribute
  hash_key = "LockID"

  # Attribute LockID is required for TF to use this table for lock state
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name          = var.dynamodb_state_locking_table_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
  }
}

output "dynamodb_state_locking_table" {
  value = aws_dynamodb_table.tf_lock_state.name
}

# Build an AWS S3 bucket for logging
resource "aws_s3_bucket" "s3_logging_bucket" {
  bucket = var.s3_logging_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name          = var.s3_logging_bucket_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
  }
}

output "s3_logging_bucket_id" {
  value = aws_s3_bucket.s3_logging_bucket.id
}

output "s3_logging_bucket" {
  value = aws_s3_bucket.s3_logging_bucket.bucket
}

# Create an IAM role for CodeBuild to assume
resource "aws_iam_role" "codebuild_iam_role" {
  name = var.codebuild_iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name          = var.codebuild_iam_role_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
  }
}

# Output the CodeBuild IAM role
output "codebuild_iam_role_arn" {
  value = aws_iam_role.codebuild_iam_role.arn
}

# Create an IAM role policy for CodeBuild to use implicitly
resource "aws_iam_role_policy" "codebuild_iam_role_policy" {
  name = var.codebuild_iam_role_policy_name
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.s3_logging_bucket.arn}",
        "${aws_s3_bucket.s3_logging_bucket.arn}/*",
        "${aws_s3_bucket.state_bucket.arn}",
        "${aws_s3_bucket.state_bucket.arn}/*",
        "arn:aws:s3:::codepipeline-eu-central-1*",
        "arn:aws:s3:::codepipeline-eu-central-1*/*",
        "${var.codepipeline_artifact_bucket_arn}",
        "${var.codepipeline_artifact_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": "${aws_dynamodb_table.tf_lock_state.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:BatchGet*",
        "codecommit:BatchDescribe*",
        "codecommit:Describe*",
        "codecommit:EvaluatePullRequestApprovalRules",
        "codecommit:Get*",
        "codecommit:List*",
        "codecommit:GitPull"
      ],
      "Resource": "${var.codecommit_repo_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:Get*",
        "iam:List*"
      ],
      "Resource": "${aws_iam_role.codebuild_iam_role.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${aws_iam_role.codebuild_iam_role.arn}"
    }
  ]
}
POLICY
}

# Create IAM role for Terraform builder to assume
resource "aws_iam_role" "tf_iam_assumed_role" {
  name = var.terraform_iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.codebuild_iam_role.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name          = var.terraform_iam_role_name
    Terraform     = "true"
    ApplicationID = var.application_id
    Project       = var.project_name
    Region        = "ec1"
    Environment   = var.environment
  }
}

# Create broad IAM policy Terraform to use to build, modify resources
resource "aws_iam_role_policy" "tf_iam_assumed_policy" {
  name = var.terraform_iam_role_policy_name
  role = aws_iam_role.tf_iam_assumed_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAllPermissions",
      "Effect": "Allow",
      "Action": [
        "*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
