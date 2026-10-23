output "python_function_name" {
  value = module.lambda_python.function_name
}

output "python_function_arn" {
  value = module.lambda_python.function_arn
}

output "python_invoke_arn" {
  value = module.lambda_python.invoke_arn
}

output "nodejs_function_name" {
  value = module.lambda_nodejs.function_name
}

output "nodejs_function_arn" {
  value = module.lambda_nodejs.function_arn
}

output "nodejs_invoke_arn" {
  value = module.lambda_nodejs.invoke_arn
}

output "api_invoke_url" {
  value = module.api_gateway.invoke_url
}

output "python_url" {
  value = "${module.api_gateway.invoke_url}/python"
}

output "nodejs_url" {
  value = "${module.api_gateway.invoke_url}/nodejs"
}
