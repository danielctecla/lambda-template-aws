locals {
  src_dir = "${path.root}/../../src"

  # Functions exposed through the API, keyed by route path
  routes = {
    for k, l in var.lambdas : coalesce(l.route_path, k) => {
      http_method       = l.http_method
      lambda_invoke_arn = module.lambda[k].invoke_arn
    } if l.expose
  }
}

module "lambda" {
  source   = "../modules/lambda"
  for_each = var.lambdas

  function_name          = "${var.project_name}-${each.key}"
  description            = each.value.description
  source_dir             = "${local.src_dir}/${each.value.source_dir}"
  runtime                = each.value.runtime
  handler                = each.value.handler
  memory_size            = each.value.memory_size
  timeout                = each.value.timeout
  architectures          = each.value.architectures
  environment_variables  = each.value.environment_variables
  log_retention_days     = each.value.log_retention_days
  api_gateway_source_arn = each.value.expose ? "${module.api_gateway.execution_arn}/*/*" : null
  permissions_boundary   = var.permissions_boundary_arn
}

module "api_gateway" {
  source = "../modules/api_gateway"

  api_name    = coalesce(var.api.name, var.project_name)
  description = coalesce(var.api.description, "REST API for ${var.project_name}")
  stage_name  = var.api.stage_name
  routes      = local.routes
}
