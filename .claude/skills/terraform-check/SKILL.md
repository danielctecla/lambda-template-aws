---
name: terraform-check
description: Test the Terraform code in iac/ without deploying. Use when the user asks to check, test, validate or plan the Terraform code.
---

# Terraform check

## Rules

- **Never run `terraform apply` or `terraform destroy`, even if the user asks.** If they want to deploy, give them the exact command to run themselves.
- Don't edit `.tf` files to make a check pass unless the user asks. Report the error first.
- Don't commit `.terraform/` or `.build/`. Do commit `iac/env/.terraform.lock.hcl`.

## Steps

Run from the project root and stop at the first failure:

```bash
terraform fmt -check -recursive iac
terraform -chdir=iac/env init -input=false        # needs backend credentials if the backend is remote
terraform -chdir=iac/env validate
terraform -chdir=iac/env plan -input=false -lock=false   # needs AWS credentials
```

If `init` fails only because credentials are missing, run `terraform -chdir=iac/env init -input=false -backend=false`, then `validate`, and report the plan as skipped (no credentials).

Report each step as pass, fail or skipped. For the plan, give the `Plan:` line and point out anything that would be destroyed or replaced.
