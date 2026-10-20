locals {
  src_dir = "${path.root}/../../src"
}

module "lambda_python" {
  source = "../modules/lambda"

  function_name = "${var.project_name}-python"
  description   = "Python Lambda"
  source_dir    = "${local.src_dir}/python"
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"
}

module "lambda_nodejs" {
  source = "../modules/lambda"

  function_name = "${var.project_name}-nodejs"
  description   = "Node.js Lambda"
  source_dir    = "${local.src_dir}/nodejs"
  runtime       = "nodejs24.x"
  handler       = "index.handler"
}
