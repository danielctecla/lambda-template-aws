output "rest_api_id" {
  description = "ID of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  description = "Execution ARN, used to grant API Gateway permission to invoke Lambda."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "stage_name" {
  description = "Name of the deployment stage."
  value       = aws_api_gateway_stage.this.stage_name
}

output "invoke_url" {
  description = "Base URL of the stage. Append the route path, e.g. <invoke_url>/python."
  value       = aws_api_gateway_stage.this.invoke_url
}
