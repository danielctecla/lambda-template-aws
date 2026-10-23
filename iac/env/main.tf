locals {
  src_dir = "${path.root}/../../src"
}

module "lambda_python" {
  source = "../modules/lambda"

  function_name          = "${var.project_name}-python"
  description            = "Python Lambda"
  source_dir             = "${local.src_dir}/python"
  runtime                = "python3.14"
  handler                = "handler.lambda_handler"
  api_gateway_source_arn = "${module.api_gateway.execution_arn}/*/*"
}

module "lambda_nodejs" {
  source = "../modules/lambda"

  function_name          = "${var.project_name}-nodejs"
  description            = "Node.js Lambda"
  source_dir             = "${local.src_dir}/nodejs"
  runtime                = "nodejs24.x"
  handler                = "index.handler"
  api_gateway_source_arn = "${module.api_gateway.execution_arn}/*/*"
}

module "api_gateway" {
  source = "../modules/api_gateway"

  api_name    = var.project_name
  description = "REST API for ${var.project_name}"

  routes = {
    python = { lambda_invoke_arn = module.lambda_python.invoke_arn }
    nodejs = { lambda_invoke_arn = module.lambda_nodejs.invoke_arn }
  }
}
