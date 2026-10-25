# Main configuration. Edit this file to rename or add functions and change the API.

project_name = "lambda-template"
aws_region   = "us-east-1"

# Extra tags on every resource (Project and ManagedBy are always added)
tags = {}

api = {
  # name        = "my-api"          # default: project_name
  # description = "My REST API"
  stage_name = "v1" # part of the URL: https://<id>.execute-api.<region>.amazonaws.com/v1

  # Requests per second (extra requests get HTTP 429) and X-Ray tracing
  throttling_rate_limit  = 5
  throttling_burst_limit = 10
  xray_tracing_enabled   = true
}

# Each key becomes the function name <project_name>-<key> and, by default,
# the route GET /<key>. source_dir is relative to src/.
lambdas = {
  python = {
    source_dir  = "python"
    runtime     = "python3.14"
    handler     = "handler.lambda_handler"
    description = "Python Lambda"
  }

  nodejs = {
    source_dir  = "nodejs"
    runtime     = "nodejs24.x"
    handler     = "index.handler"
    description = "Node.js Lambda"

    # Optional settings (defaults shown)
    # memory_size           = 128
    # timeout               = 10
    # architectures         = ["x86_64"]
    # environment_variables = {}
    # log_retention_days    = 14
    # tracing_mode          = "Active" # X-Ray: "Active" or "PassThrough"
    # expose                = true     # false = not reachable through the API
    # route_path            = "nodejs" # default: the key
    # http_method           = "GET"
  }
}
