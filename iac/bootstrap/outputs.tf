output "deploy_role_arn" {
  description = "Role Terraform assumes to deploy iac/env. Set it as deploy_role_arn in iac/env/credentials.auto.tfvars."
  value       = aws_iam_role.deployer.arn
}

output "permissions_boundary_arn" {
  description = "Boundary required on Lambda roles. Set it as permissions_boundary_arn in iac/env/credentials.auto.tfvars."
  value       = aws_iam_policy.boundary.arn
}

output "trusted_principal_arns" {
  description = "IAM users or roles that can assume the deploy role."
  value       = local.trusted_principal_arns
}

output "trusted_sso_permission_sets" {
  description = "Permission sets whose SSO users can assume the deploy role."
  value       = local.sso_permission_sets
}
