variable "project_name" {
  description = "Name of the business project"
}

variable "application_id" {
  description = "Name of the specific application"
}

variable "branch_name" {
  description = "Name of the code repository branch"
}

variable "environment" {
  description = "Application environment (dev/prod)"
}

variable "terraform_version" {
  description = "Version of Terraform to be used to set up infrastructure in CI/CD"
  default     = "0.15.1"
}
