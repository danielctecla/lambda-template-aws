# Must match project_name and aws_region in iac/env
project_name = "lambda-template"
aws_region   = "us-east-1"

# Who can assume the deploy role. Default: whoever runs this bootstrap
# (for an SSO session, its whole permission set).
# sso_permission_sets = ["AdministratorAccess"]
