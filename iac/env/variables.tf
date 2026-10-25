variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as prefix for resource names."
  type        = string
}

variable "deploy_role_arn" {
  description = "IAM role Terraform assumes to deploy (output of iac/bootstrap). If null, your current AWS credentials are used directly."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary set on the Lambda roles (output of iac/bootstrap). Required when deploying with deploy_role_arn."
  type        = string
  default     = null
}
