---
name: terraform-check
description: Test the Terraform code in iac/ without deploying. Use when the user asks to check, test, validate or plan the Terraform code.
---

# Terraform check

## Rules

- **Never run `terraform apply` or `terraform destroy`.** If the user wants to deploy, ask them to confirm first.
- Don't edit `.tf` files to make a check pass unless the user asks. Report the error first.
- Don't commit `.terraform/` or `.build/`. Do commit `iac/env/.terraform.lock.hcl`.

## Steps

Run from the project root and stop at the first failure:

```bash
terraform fmt -check -recursive iac
terraform -chdir=iac/env init -input=false
terraform -chdir=iac/env validate
terraform -chdir=iac/env plan -input=false -lock=false   # needs AWS credentials
```

Report each step as pass or fail. For the plan, give the `Plan:` line and point out anything that would be destroyed or replaced.
