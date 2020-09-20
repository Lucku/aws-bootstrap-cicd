# Bootstrap CI/CD Resources

Terraform files for bootstrapping a complete development environment in AWS, consisting a source code repository, build step, resource deployment via Terraform and a CI/CD pipeline that glues everything together. The pipeline looks as follows:

`(Source) -> (Build) -> (TerraformPlan -> TerraformApply)`

## Requisites

An AWS User privileged to perform the deployment of the resources via Terraform.

## Usage

- Use `terraform init` to initialize the Terraform project.
- Use `terraform plan` and define the input variables to see the resources to be created
- Use `terraform apply` and provide the input variables to instruct Terraform to create the resources

## Input Variables

- `application_id`: Name of the specific application
- `project_name`: Name of the higher level project
- `environment`: The environment of the application (dev/prod)
- `branch_name`: Branch of the source code repository that contains the state of the desired environment

## Resource Naming

Resources will usually be named using the following schema: {application_id}-{purpose}-{resource-type}-{environment}. Where the purpose or resource type is implicit, these segments are omitted. Source code repositories are simply named after the application ID.

Examples are:
- **exampleapp**-**artifact**-**bucket**-**dev**
- **exampleapp**-**pipeline**-**prod**

## Considerations

In order to run the CI/CD pipeline, the code repository needs to include a correctly defined `buildspec.yml` file under the branch of the respective environment. A `buildspec.yml` for source code in Go can be found as part of this repository.

The Terraform files in the generated repository have to reside in the directory `infrastructure/` and need to define an empty S3 backend block:

```hcl
terraform {
  backend "s3" {}
}
```

The rest of the backend configuration parameters is provided by the build specification.

Build outputs from the application being built in the pipeline have to reside in a `bin/` directory. This is important since all other repository files except the ones in `bin` and `infrastructure` are left behind before the `TerraformApply` step.

Don't forget to set the IAM role that is assumed by Terraform and created as part of this deployment, in your own infrastructure scripts:

```hcl
provider "aws" {
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME"
  }
}
```

The permissions of CodeBuild are chosen only to perform CodeBuild-specific tasks, not to spin-up other resources. As part of this repo, Terraform will be able to do literally everything, so please be careful or feel free to adjust the code and define fine-grained permissions for the Terraform role.