output "api_invoke_url" {
  description = "Base URL of the API stage."
  value       = module.api_gateway.invoke_url
}

output "function_arns" {
  description = "Lambda function ARNs, by key."
  value       = { for k, m in module.lambda : k => m.function_arn }
}

output "function_names" {
  description = "Lambda function names, by key."
  value       = { for k, m in module.lambda : k => m.function_name }
}

output "urls" {
  description = "Full URL of each exposed function, by route path."
  value       = { for path, _ in local.routes : path => "${module.api_gateway.invoke_url}/${path}" }
}
