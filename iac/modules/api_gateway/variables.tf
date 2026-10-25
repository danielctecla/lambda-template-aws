variable "api_name" {
  description = "Name of the REST API."
  type        = string
}

variable "description" {
  description = "Description of the REST API."
  type        = string
  default     = ""
}

variable "routes" {
  description = "Routes to expose, keyed by path part (e.g. \"python\" -> /python). Each route proxies to a Lambda function."
  type = map(object({
    http_method       = optional(string, "GET")
    lambda_invoke_arn = string
  }))
}

variable "stage_name" {
  description = "Name of the deployment stage. Part of the invoke URL."
  type        = string
  default     = "v1"
}

variable "tags" {
  description = "Tags applied to all resources of the module."
  type        = map(string)
  default     = {}
}

variable "throttling_burst_limit" {
  description = "Maximum number of concurrent requests the stage accepts in a burst."
  type        = number
  default     = 10
}

variable "throttling_rate_limit" {
  description = "Steady-state requests per second the stage accepts. Extra requests get HTTP 429."
  type        = number
  default     = 5
}

variable "xray_tracing_enabled" {
  description = "Enable AWS X-Ray tracing on the stage."
  type        = bool
  default     = true
}
