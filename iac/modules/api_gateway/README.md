# API Gateway module

REST API (API Gateway v1) that proxies routes to Lambda functions. It creates:

- REST API (regional endpoint)
- One resource, method and Lambda proxy integration (`AWS_PROXY`) per route
- Deployment, redeployed automatically when routes change
- Stage

It does not create the Lambda invoke permission. Pass `execution_arn` to the Lambda module's `api_gateway_source_arn` instead.

## Usage

```hcl
module "api_gateway" {
  source = "../modules/api_gateway"

  api_name = "my-app"

  routes = {
    python = { lambda_invoke_arn = module.lambda_python.invoke_arn }                       # GET /python
    nodejs = { http_method = "GET", lambda_invoke_arn = module.lambda_nodejs.invoke_arn } # GET /nodejs
  }
}

module "lambda_python" {
  source = "../modules/lambda"
  # ...
  api_gateway_source_arn = "${module.api_gateway.execution_arn}/*/*"
}
```

## Inputs

| Name | Type | Default | Required |
|------|------|---------|:--------:|
| api_name | string | - | yes |
| routes | map(object({ http_method = optional(string, "GET"), lambda_invoke_arn = string })) | - | yes |
| description | string | `""` | no |
| stage_name | string | `"v1"` | no |
| tags | map(string) | `{}` | no |

## Outputs

`rest_api_id`, `execution_arn`, `stage_name`, `invoke_url`
