# lambda-template-aws

Terraform template to deploy AWS Lambda functions (Python and Node.js examples) behind an API Gateway REST API.

## Requirements

- Terraform >= 1.16 and AWS CLI v2
- An IAM Identity Center (SSO) user with admin access, see [Credentials](#credentials)

## Structure

```
src/             Lambda code (python/, nodejs/)
iac/bootstrap/   Deploy role and permissions boundary (run once)
iac/env/         Lambdas and API, configured in terraform.tfvars
iac/modules/     Reusable modules (lambda/, api_gateway/)
scripts/         destroy.sh
```

## Configuration

Edit `iac/env/terraform.tfvars`: `project_name`, `aws_region` (default `us-east-1`), `tags`, `api` (name, stage, throttling, X-Ray) and `lambdas`. Each key in `lambdas` is deployed as `<project_name>-<key>` at `GET /<key>`:

```hcl
lambdas = {
  orders = {
    source_dir = "orders" # folder under src/
    runtime    = "python3.14"
    handler    = "handler.lambda_handler"
    # Optional: memory_size, timeout, environment_variables, route_path, http_method, expose = false, ...
  }
}
```

Keep `project_name` and `aws_region` the same in `iac/bootstrap/terraform.tfvars`.

## Credentials

No long-lived access keys. You sign in with SSO (temporary credentials, MFA), and Terraform deploys by assuming the `<project>-deployer` role. That role can only manage `<project>-*` resources in one region, and every Lambda role gets a permissions boundary (logs and X-Ray only). Details in [iac/bootstrap](iac/bootstrap/README.md).

One-time setup:

1. In **IAM Identity Center**: enable it with AWS Organizations, require MFA, add your user, then create the `AdministratorAccess` permission set and assign it to your account.
2. Run `aws configure sso` and name the profile `lambda-template`. The start URL is on the Identity Center dashboard.
3. Once a deploy works with SSO, deactivate and then delete your IAM user's access keys.

## Deploy

From the repo root:

```bash
aws sso login --profile lambda-template
export AWS_PROFILE=lambda-template

# 1. Deploy role (once)
terraform -chdir=iac/bootstrap init
terraform -chdir=iac/bootstrap apply

# 2. Point iac/env at it (this file is gitignored)
cat > iac/env/credentials.auto.tfvars <<VARS
deploy_role_arn          = "$(terraform -chdir=iac/bootstrap output -raw deploy_role_arn)"
permissions_boundary_arn = "$(terraform -chdir=iac/bootstrap output -raw permissions_boundary_arn)"
VARS

# 3. Lambdas and API
terraform -chdir=iac/env init
terraform -chdir=iac/env apply
terraform -chdir=iac/env output urls
```

Terraform state is stored locally in each stack folder (no S3), so don't delete it while resources exist. `AccessDenied` on apply means the deploy role lacks a permission: add it in `iac/bootstrap/main.tf` and apply the bootstrap again.

## Tests

Handler tests run in GitHub Actions on every push to `main` and every pull request. To run them locally:

```bash
pip install pytest && pytest tests/python
node --test "tests/nodejs/**/*.test.mjs"
```

## Teardown

```bash
scripts/destroy.sh                   # Lambdas, API, roles, log groups
scripts/destroy.sh --with-bootstrap  # also the deploy role and boundary
```

It shows the account, plans the destroy and asks you to type the project name before applying. Set `EXPECTED_ACCOUNT_ID` to abort on the wrong account.

## Cost

Built for the Free Tier: Lambda, CloudWatch Logs and X-Ray are always free at this scale. API Gateway is free for the account's first 12 months (or covered by credits on the new Free plan), then about $3.50 per million calls. Throttling (5 requests per second) limits surprise costs, and a **zero spend budget** in **Billing → Budgets** emails you if anything is charged.

## Public repository

Never commit credentials or account-specific values. `*.auto.tfvars` and `*.tfstate` are gitignored because they contain your account ID.
