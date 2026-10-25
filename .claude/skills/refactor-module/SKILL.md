---
name: refactor-module
description: Refactor Terraform code into reusable modules without recreating resources. Use when the user asks to modularize, extract a module, or clean up repeated Terraform code.
---

# Refactor module

## 1. Decide first

Before editing anything, check whether a module is worth it. Refactor only if at least one is true:

- The same group of resources is repeated (copy-pasted blocks, `_1`, `_2` suffixes).
- A group of resources is used, or will be used, in more than one environment or place.
- A single file is hard to follow because unrelated resources are mixed together.

If none is true, **change nothing**. Tell the user in one or two lines why a module isn't needed and stop.

## Rules

- **Never run `terraform apply` or `terraform destroy`.** Give the user the command to run themselves.
- Never print state contents: state stores secrets in plaintext.
- No resource may be destroyed or recreated. The refactor is done only when `plan` shows no changes.
- Keep modules small and specific: typed variables with descriptions, no `map(any)` catch-all inputs.
- Don't introduce a module wrapper around a single resource.

## 2. Map current state

```bash
terraform state list
```

Use these addresses as the `from` side of the migration. Don't parse `terraform.tfstate` by hand.

## 3. Refactor

- Put the module in `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`.
- Replace repeated blocks with `for_each` keyed by a stable value (a name or AZ, not a list index).
- Pass dependencies between modules through the root module via outputs.
- Version pinning: registry sources use `version = "~> X.Y"`; git sources use `?ref=vX.Y.Z` in `source` (no `version` argument).

## 4. Migrate state with `moved` blocks (Terraform 1.1+)

```hcl
moved {
  from = aws_subnet.public_1
  to   = module.vpc.aws_subnet.public["us-east-1a"]
}
```

One `moved` block per resource whose address changed. For Terraform < 1.1, give the user the equivalent `terraform state mv` commands instead of running them.

## 5. Verify

Run `terraform fmt`, `validate` and `plan`. Report the `Plan:` line. If it shows anything to add, change or destroy, fix the `moved` blocks or the module, and don't call the refactor done.
