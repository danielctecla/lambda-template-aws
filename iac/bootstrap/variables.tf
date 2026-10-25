variable "aws_region" {
  description = "AWS region where the main stack (iac/env) is deployed. The deploy role is scoped to it."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name. Must match project_name in iac/env, since permissions are scoped by this prefix."
  type        = string
}

variable "sso_permission_sets" {
  description = "IAM Identity Center permission set names whose users may assume the deploy role, e.g. [\"AdministratorAccess\"]. If this and trusted_principal_arns are empty, the identity running the bootstrap is trusted (for an SSO session, its permission set)."
  type        = list(string)
  default     = []
}

variable "trusted_principal_arns" {
  description = "IAM user or role ARNs allowed to assume the deploy role. Prefer sso_permission_sets: IAM users need long-lived access keys."
  type        = list(string)
  default     = []
}

variable "require_mfa" {
  description = "Require MFA for trusted_principal_arns. Not needed for SSO, which enforces MFA at sign-in (and doesn't pass it on to chained roles)."
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the deploy role. When assumed from an SSO session (role chaining), AWS caps it at 3600."
  type        = number
  default     = 3600
}
