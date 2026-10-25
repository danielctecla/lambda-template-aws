# Bootstrap: deploy credentials

Run once, logged in with your IAM Identity Center (SSO) profile, before deploying `iac/env`. It creates:

- `<project>-deployer`: IAM role Terraform assumes to deploy. Short-lived STS credentials, no access keys. Trusted by SSO permission sets and/or IAM principals, see below.
- `<project>-deployer` policy: only what `iac/env` needs (Lambda, API Gateway, logs and IAM roles/policies named `<project>-*`), scoped to one region.
- `<project>-boundary`: permissions boundary every Lambda role must have, so the deploy role can't create functions that do more than write logs and send X-Ray traces.

The deploy role can't edit itself, its policy or the boundary.

## Usage

```bash
cd iac/bootstrap
terraform init
terraform apply
```

Copy the outputs into `iac/env/credentials.auto.tfvars` (gitignored, see the `.example` file):

```bash
cd ../env
cat > credentials.auto.tfvars <<VARS
deploy_role_arn          = "$(terraform -chdir=../bootstrap output -raw deploy_role_arn)"
permissions_boundary_arn = "$(terraform -chdir=../bootstrap output -raw permissions_boundary_arn)"
VARS
```

`project_name` and `aws_region` must match the ones in `iac/env`.

## Who can assume the deploy role

| Set | Trusted |
|-----|---------|
| Nothing (default) | The identity running the bootstrap: its permission set for an SSO session, otherwise its IAM user or role |
| `sso_permission_sets = ["AdministratorAccess"]` | Every SSO user signed in to this account with that permission set |
| `trusted_principal_arns = [...]` | Those IAM users or roles. Add `require_mfa = true` for IAM users |

SSO roles are matched with `aws:PrincipalArn` by name pattern (`AWSReservedSSO_<permission set>_*`), because their random suffix changes if the permission set is re-provisioned. MFA for SSO users is enforced by Identity Center at sign-in; `require_mfa` only applies to `trusted_principal_arns`.

With the default, re-running the bootstrap as a different identity changes who is trusted. Check the `trusted_sso_permission_sets` and `trusted_principal_arns` outputs, or set one of them explicitly.

When assumed from an SSO session (role chaining), AWS caps the deploy role's session at 1 hour.

## Inputs

| Name | Type | Default | Required |
|------|------|---------|:--------:|
| project_name | string | - | yes |
| aws_region | string | `"us-east-1"` | no |
| sso_permission_sets | list(string) | `[]` (current caller) | no |
| trusted_principal_arns | list(string) | `[]` (current caller) | no |
| require_mfa | bool | `false` | no |
| max_session_duration | number | `3600` | no |

## Outputs

`deploy_role_arn`, `permissions_boundary_arn`, `trusted_sso_permission_sets`, `trusted_principal_arns`
