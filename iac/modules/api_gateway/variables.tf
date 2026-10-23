variable "api_name" {
  description = "Name of the REST API."
  type        = string
}

variable "description" {
  description = "Description of the REST API."
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Name of the deployment stage. Part of the invoke URL."
  type        = string
  default     = "v1"
}

variable "routes" {
  description = "Routes to expose, keyed by path part (e.g. \"python\" -> /python). Each route proxies to a Lambda function."
  type = map(object({
    http_method       = optional(string, "GET")
    lambda_invoke_arn = string
  }))
}

variable "tags" {
  description = "Tags applied to all resources of the module."
  type        = map(string)
  default     = {}
}
