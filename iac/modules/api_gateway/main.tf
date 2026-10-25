# 1. REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_name
  description = var.description
  tags        = var.tags

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 2. One resource (path) per route, under the root path
resource "aws_api_gateway_resource" "route" {
  for_each = var.routes

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.key
}

# 3. Method on each resource (public, no authorization)
resource "aws_api_gateway_method" "route" {
  for_each = var.routes

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.route[each.key].id
  http_method   = each.value.http_method
  authorization = "NONE"
}

# 4. Lambda proxy integration (API Gateway always calls Lambda with POST)
resource "aws_api_gateway_integration" "route" {
  for_each = var.routes

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.route[each.key].id
  http_method             = aws_api_gateway_method.route[each.key].http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = each.value.lambda_invoke_arn
}

# 5. Deployment, recreated whenever the routes change
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.route,
      aws_api_gateway_method.route,
      aws_api_gateway_integration.route,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.route]
}

# 6. Stage that serves the deployment
resource "aws_api_gateway_stage" "main" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  deployment_id        = aws_api_gateway_deployment.main.id
  stage_name           = var.stage_name
  xray_tracing_enabled = var.xray_tracing_enabled
  tags                 = var.tags
}

# 7. Throttling for every method of the stage, so a flood of requests can't run up the bill
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}
