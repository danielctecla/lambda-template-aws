variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as prefix for resource names."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all resources, on top of Project and ManagedBy."
  type        = map(string)
  default     = {}
}

variable "api" {
  description = "REST API settings. name defaults to project_name."
  type = object({
    name        = optional(string)
    description = optional(string)
    stage_name  = optional(string, "v1")
  })
  default = {}
}

variable "lambdas" {
  description = "Lambda functions to deploy, keyed by name. Each is deployed as <project_name>-<key>. source_dir is relative to src/. Each function is exposed at <http_method> /<route_path> (default GET /<key>); set expose = false to keep it out of the API."
  type = map(object({
    source_dir            = string
    runtime               = string
    handler               = string
    description           = optional(string, "")
    memory_size           = optional(number, 128)
    timeout               = optional(number, 10)
    architectures         = optional(list(string), ["x86_64"])
    environment_variables = optional(map(string), {})
    log_retention_days    = optional(number, 14)
    expose                = optional(bool, true)
    route_path            = optional(string)
    http_method           = optional(string, "GET")
  }))

  validation {
    condition     = alltrue([for k in keys(var.lambdas) : can(regex("^[A-Za-z0-9_-]+$", k))])
    error_message = "Lambda keys may only contain letters, numbers, hyphens and underscores."
  }

  validation {
    condition     = anytrue([for l in values(var.lambdas) : l.expose])
    error_message = "At least one Lambda must have expose = true, since the API needs a route."
  }

  validation {
    condition     = length(distinct([for k, l in var.lambdas : coalesce(l.route_path, k) if l.expose])) == length([for l in values(var.lambdas) : l if l.expose])
    error_message = "Exposed Lambdas must have unique route paths."
  }
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
