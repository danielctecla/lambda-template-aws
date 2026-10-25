locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = var.aws_region
  prefix     = var.project_name

  # If nothing is set, trust whoever runs the bootstrap: for an SSO session its
  # whole permission set, otherwise its IAM user or role
  caller_arn            = data.aws_iam_session_context.current.issuer_arn
  caller_permission_set = try(regex(":role/aws-reserved/sso\\.amazonaws\\.com/(?:[^/]+/)?AWSReservedSSO_(.+)_[0-9a-f]+$", local.caller_arn)[0], null)
  trust_caller          = length(var.sso_permission_sets) == 0 && length(var.trusted_principal_arns) == 0

  sso_permission_sets    = local.trust_caller && local.caller_permission_set != null ? [local.caller_permission_set] : var.sso_permission_sets
  trusted_principal_arns = local.trust_caller && local.caller_permission_set == null ? [local.caller_arn] : var.trusted_principal_arns

  # SSO role names end in a random suffix that changes if the permission set is
  # re-provisioned, so they're matched by pattern instead of by exact ARN
  sso_role_arns = [
    for ps in local.sso_permission_sets :
    "arn:${local.partition}:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/*AWSReservedSSO_${ps}_*"
  ]

  # Name patterns of what iac/env creates. They deliberately don't match the
  # deployer role or the boundary, so the deploy role can't modify itself.
  lambda_role_arn   = "arn:${local.partition}:iam::${local.account_id}:role/${local.prefix}-*-role"
  lambda_policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/${local.prefix}-*-policy"
  function_arn      = "arn:${local.partition}:lambda:${local.region}:${local.account_id}:function:${local.prefix}-*"
  log_group_arn     = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.prefix}-*"
  boundary_arn      = "arn:${local.partition}:iam::${local.account_id}:policy/${local.prefix}-boundary"
  deployer_role_arn = "arn:${local.partition}:iam::${local.account_id}:role/${local.prefix}-deployer"
  deployer_pol_arn  = "arn:${local.partition}:iam::${local.account_id}:policy/${local.prefix}-deployer"
}
