variable "api_gateway_source_arn" {
  description = "API Gateway execution ARN allowed to invoke the function (e.g. arn:aws:execute-api:region:account:api-id/*). If null, no permission is created."
  type        = string
  default     = null
}

variable "architectures" {
  description = "Instruction set architecture: [\"x86_64\"] or [\"arm64\"]."
  type        = list(string)
  default     = ["x86_64"]
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "function_name" {
  description = "Name of the Lambda function. Also used to name the IAM role, policy and log group."
  type        = string
}

variable "handler" {
  description = "Function entrypoint, e.g. handler.lambda_handler (Python) or index.handler (Node.js)."
  type        = string
}

variable "log_retention_days" {
  description = "Days to keep the function logs in CloudWatch."
  type        = number
  default     = 14
}

variable "memory_size" {
  description = "Memory in MB available to the function."
  type        = number
  default     = 128
}

variable "permissions_boundary" {
  description = "ARN of the IAM policy used as permissions boundary for the role. If null, no boundary is set."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime, e.g. python3.14 or nodejs24.x."
  type        = string
}

variable "source_dir" {
  description = "Path to the directory with the function code. It is zipped automatically."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources of the module."
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Maximum execution time in seconds."
  type        = number
  default     = 10
}

variable "tracing_mode" {
  description = "AWS X-Ray tracing mode: \"Active\" samples and traces requests, \"PassThrough\" only forwards trace headers."
  type        = string
  default     = "Active"

  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "tracing_mode must be Active or PassThrough."
  }
}
