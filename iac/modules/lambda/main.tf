# 1. IAM role assumed by the Lambda service
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# 2. IAM policy: basic permissions to write logs to its own log group
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.function_name}-policy"
  description = "Basic execution policy for ${var.function_name}"
  policy      = data.aws_iam_policy_document.lambda_logging.json
  tags        = var.tags
}

# 3. Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# 4. Log group, created up front so retention is managed by Terraform
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# 5. Zip the source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.function_name}.zip"
}

# 6. Lambda function
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = var.description
  role             = aws_iam_role.lambda.arn
  runtime          = var.runtime
  handler          = var.handler
  memory_size      = var.memory_size
  timeout          = var.timeout
  architectures    = var.architectures
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda,
    aws_cloudwatch_log_group.lambda,
  ]
}

# 7. Allow API Gateway to invoke the function (only when a source ARN is given)
resource "aws_lambda_permission" "api_gateway" {
  count = var.api_gateway_source_arn == null ? 0 : 1

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_source_arn
}
