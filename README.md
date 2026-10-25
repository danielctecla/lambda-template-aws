# lambda-template-aws

Terraform template to deploy AWS Lambda functions (Python and Node.js examples) behind an API Gateway REST API.

## Requirements

- Terraform >= 1.16
- AWS CLI v2
- An IAM Identity Center (SSO) user with admin access to the account, see [Credentials](#credentials)

## Structure

```
src/             Lambda code (python/, nodejs/)
iac/bootstrap/   Deploy role and permissions boundary (run once)
iac/env/         Terraform config to deploy
iac/modules/     Reusable modules (lambda/, api_gateway/)
scripts/         Helper scripts (destroy.sh)
```

## Configuration

Everything you'd normally change is in `iac/env/terraform.tfvars`:

| Setting | What it controls |
|---------|------------------|
| `project_name` | Prefix of every resource name |
| `aws_region` | Region to deploy to |
| `tags` | Extra tags on every resource |
| `api` | API `name` (default `project_name`), `description`, `stage_name` (part of the URL), throttling (`throttling_rate_limit` requests per second, default 5, and `throttling_burst_limit`, default 10) and `xray_tracing_enabled` (default `true`) |
| `lambdas` | One entry per function, see below |

Each key in `lambdas` is deployed as `<project_name>-<key>`, exposed at `GET /<key>` by default:

```hcl
lambdas = {
  orders = {
    source_dir = "orders"          # folder under src/
    runtime    = "python3.14"
    handler    = "handler.lambda_handler"

    # Optional (defaults shown)
    description           = ""
    memory_size           = 128
    timeout               = 10
    architectures         = ["x86_64"]
    environment_variables = {}
    log_retention_days    = 14
    tracing_mode          = "Active"   # X-Ray: "Active" or "PassThrough"
    expose                = true     # false = not reachable through the API
    route_path            = "orders" # default: the key
    http_method           = "GET"
  }
}
```

To add a function, create its folder in `src/` and add an entry. To rename one, change its key; Terraform will replace it.

Function names are always prefixed with `project_name`, because the deploy role's permissions are scoped to `<project_name>-*`. If you change `project_name` or `aws_region`, set the same values in `iac/bootstrap/terraform.tfvars` and re-apply the bootstrap.

## What gets created

| Stack | Resources |
|-------|-----------|
| `iac/bootstrap` | `<project>-deployer` IAM role and policy, `<project>-boundary` permissions boundary |
| `iac/env` | One Lambda function per `lambdas` entry, with its IAM role, policy and CloudWatch log group, and a REST API with a route per exposed function |

No S3 bucket is created. Terraform state is stored locally (`terraform.tfstate` in each stack folder) and the Lambda code is zipped locally and uploaded directly to Lambda. To use a remote S3 backend, see `iac/env/backend.tf`; that bucket is not managed by this template.

Everything is deployed to `aws_region` (default `us-east-1`), not to your AWS CLI default region.

## Cost

Built to stay within the AWS Free Tier for personal use. No KMS keys or other resources with a fixed monthly price are created.

| Service | Free Tier |
|---------|-----------|
| Lambda | Always free: 1M requests and 400,000 GB-seconds per month |
| CloudWatch Logs, X-Ray | Always free monthly allowances, far above what testing uses |
| IAM | Free |
| API Gateway (REST) | Free for the first 12 months on the legacy Free Tier (1M calls per month), or paid from credits on the Free plan. After that, about $3.50 per million calls |

Free Tier allowances are per account, shared with anything else running in it. Throttling (5 requests per second by default) limits how fast a flood of requests can add cost. Create a **zero spend budget** in **Billing → Budgets** to get an email as soon as anything is charged, and check **Billing → Free Tier** for what your account has left.

## Credentials

No long-lived access keys are used. There are two layers:

1. **You sign in with IAM Identity Center (SSO).** `aws sso login` opens the browser, asks for your password and MFA, and gives the CLI temporary credentials that expire after a few hours.
2. **Terraform assumes the `<project>-deployer` role** from that session (created by `iac/bootstrap`), so the deploy itself runs with least privilege:
   - The role can only manage resources named `<project>-*`, in one region. API Gateway is the exception: its resources can't be scoped by name, so it is scoped to the whole region.
   - Every Lambda role must have the `<project>-boundary` permissions boundary, so a function can never do more than write its own logs and send X-Ray traces.
   - The role can't modify itself, its policy or the boundary.

### 1. Set up IAM Identity Center (once, in the AWS console)

1. Open **IAM Identity Center** and choose **Enable** with AWS Organizations. If your account isn't in an organization yet, this creates one with your account as the management account (free). The region you enable it in is your SSO region.
2. **Settings → Authentication → Multi-factor authentication**: prompt users for MFA every time they sign in, and require them to register a device at sign-in.
3. **Users → Add user** with your email. Accept the invitation email, set a password and register your MFA device.
4. **Permission sets → Create permission set → Predefined → `AdministratorAccess`**. Optionally raise the session duration (default 1 hour, max 12).
5. **AWS accounts** → select your account → **Assign users or groups** → your user → the `AdministratorAccess` permission set.
6. Copy the **AWS access portal URL** from the Identity Center dashboard (`https://d-xxxxxxxxxx.awsapps.com/start`).

### 2. Configure the AWS CLI

```bash
aws configure sso
#   SSO session name:        lambda-template
#   SSO start URL:           <AWS access portal URL>
#   SSO region:              <region where you enabled Identity Center>
#   SSO registration scopes: sso:account:access
#   (log in in the browser, then pick your account and AdministratorAccess)
#   Default client Region:   us-east-1
#   CLI profile name:        lambda-template

export AWS_PROFILE=lambda-template
aws sts get-caller-identity   # Arn should contain assumed-role/AWSReservedSSO_AdministratorAccess_
```

Every new session: `aws sso login` and `export AWS_PROFILE=lambda-template`. Terraform and `scripts/destroy.sh` use the same profile.

When `iac/bootstrap` runs from an SSO session, it automatically trusts that session's permission set, so every user with `AdministratorAccess` in this account can use the deploy role. To choose explicitly, set `sso_permission_sets` in `iac/bootstrap/terraform.tfvars`. If you ran the bootstrap before with an IAM user, run `terraform apply` there again with the SSO profile: only the role's trust policy changes.

### 3. Remove the old access keys

Once a deploy works with SSO, the IAM user's access keys aren't needed. Using the SSO profile:

```bash
aws iam list-access-keys --user-name <iam-user>

# 1. Deactivate first, and check that nothing you still use breaks
aws iam update-access-key --user-name <iam-user> --access-key-id <key-id> --status Inactive

# 2. Then delete it for good
aws iam delete-access-key --user-name <iam-user> --access-key-id <key-id>
```

Then remove the key from `~/.aws/credentials`. Anything else on your machine that used those keys (other projects, scripts) must switch to an SSO profile too. If the IAM user has no other use, you can delete it.

### Without SSO

Set `trusted_principal_arns` (and ideally `require_mfa = true`) in `iac/bootstrap/terraform.tfvars` to trust IAM users or roles instead. This works, but IAM users need long-lived access keys, which is what SSO avoids. The bootstrap and `credentials.auto.tfvars` are also optional: without them, Terraform deploys directly with your own credentials.

## Deploy

Log in first, from the repo root:

```bash
aws sso login --profile lambda-template
export AWS_PROFILE=lambda-template
```

1. Edit your code in `src/` and your settings in `iac/env/terraform.tfvars`.
2. Set the same `project_name` and `aws_region` in `iac/bootstrap/terraform.tfvars`.
3. Create the deploy role (once):

   ```bash
   cd iac/bootstrap
   terraform init
   terraform apply
   ```

4. Point `iac/env` at the role. This file is gitignored:

   ```bash
   cd ../env
   cat > credentials.auto.tfvars <<VARS
   deploy_role_arn          = "$(terraform -chdir=../bootstrap output -raw deploy_role_arn)"
   permissions_boundary_arn = "$(terraform -chdir=../bootstrap output -raw permissions_boundary_arn)"
   VARS
   ```

5. Deploy:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

6. Test the endpoints:

   ```bash
   terraform output urls          # URL of each exposed function
   curl "$(terraform output -raw api_invoke_url)/python"
   ```

If `terraform apply` in `iac/env` fails with `AccessDenied`, the deploy role is missing a permission. Add the action to the deploy policy in `iac/bootstrap/main.tf` and re-run `terraform apply` in `iac/bootstrap`.

## Teardown

```bash
scripts/destroy.sh                   # destroy iac/env (Lambdas, API, roles, log groups)
scripts/destroy.sh --with-bootstrap  # also remove the deploy role, its policy and the boundary
```

The script:

1. Shows the caller, project and region. Set `EXPECTED_ACCOUNT_ID` to abort if your credentials point to another account.
2. Plans the destroy, asks you to type the project name and applies exactly that plan.
3. Checks that nothing tagged `Project=<project>` and no `<project>-*-role` IAM roles are left (the tagging API can lag a few minutes).
4. With `--with-bootstrap`, repeats the plan and confirmation for `iac/bootstrap`.

Run it with your SSO profile (`AWS_PROFILE`). If your session expired, it stops and tells you to run `aws sso login`. After `--with-bootstrap`, nothing from this project is left in AWS. Local leftovers (`.terraform/`, `.build/`, empty state files, `credentials.auto.tfvars`) are gitignored and can be deleted.

## Public repository

Never commit credentials or account-specific values. `*.auto.tfvars` and `*.tfstate` are gitignored because they contain your account ID; only `credentials.auto.tfvars.example` with placeholders is committed.
