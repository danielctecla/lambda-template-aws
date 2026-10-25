output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.main.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.main.function_name
}

output "invoke_arn" {
  description = "Invoke ARN, used by API Gateway integrations."
  value       = aws_lambda_function.main.invoke_arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "role_arn" {
  description = "ARN of the IAM role used by the function."
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "Name of the IAM role, useful to attach extra policies."
  value       = aws_iam_role.lambda.name
}
