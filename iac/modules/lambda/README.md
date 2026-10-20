# Lambda module

General-purpose AWS Lambda module. It creates:

- IAM role assumed by Lambda
- IAM policy with basic permissions (write logs to its own log group), attached to the role
- CloudWatch log group with retention
- Zip of `source_dir` (via `archive_file`)
- Lambda function
- Optional `aws_lambda_permission` so API Gateway can invoke the function

## Usage

```hcl
module "lambda_python" {
  source = "../../modules/lambda"

  function_name = "my-app-python"
  source_dir    = "${path.root}/../../../src/python"
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"

  # Optional
  memory_size            = 256
  timeout                = 15
  environment_variables  = { LOG_LEVEL = "INFO" }
  api_gateway_source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
```

Need more permissions (S3, DynamoDB, ...)? Attach extra policies to the `role_name` output.

## Inputs

| Name | Type | Default | Required |
|------|------|---------|:--------:|
| function_name | string | - | yes |
| source_dir | string | - | yes |
| runtime | string | - | yes |
| handler | string | - | yes |
| description | string | `""` | no |
| memory_size | number | `128` | no |
| timeout | number | `10` | no |
| architectures | list(string) | `["x86_64"]` | no |
| environment_variables | map(string) | `{}` | no |
| log_retention_days | number | `14` | no |
| api_gateway_source_arn | string | `null` | no |
| tags | map(string) | `{}` | no |

## Outputs

`function_name`, `function_arn`, `invoke_arn`, `role_arn`, `role_name`, `log_group_name`
