# lambda-template-aws

Terraform template to deploy AWS Lambda functions (Python and Node.js examples) behind an API Gateway REST API.

## Requirements

- Terraform >= 1.5
- AWS credentials configured

## Structure

```
src/             Lambda code (python/, nodejs/)
iac/env/         Terraform config to deploy
iac/modules/     Reusable modules (lambda/, api_gateway/)
```

## Usage

1. Edit your code in `src/`.
2. Set your project name in `iac/env/terraform.tfvars`.
3. Deploy:

```bash
cd iac/env
terraform init
terraform plan
terraform apply
```

Test the endpoints:

```bash
curl "$(terraform output -raw python_url)"
curl "$(terraform output -raw nodejs_url)"
```

To remove everything: `terraform destroy`.
