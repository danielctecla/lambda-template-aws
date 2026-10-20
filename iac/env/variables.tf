variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as prefix for resource names."
  type        = string
}
