data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_partition" "current" {}

# 1. Permissions boundary for Lambda roles: the most any function can ever do,
#    whatever policy gets attached to its role
data "aws_iam_policy_document" "boundary" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${local.log_group_arn}:*"]
  }

  # X-Ray tracing. X-Ray doesn't support resource-level permissions.
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "boundary" {
  name        = "${local.prefix}-boundary"
  description = "Permissions boundary for ${local.prefix} Lambda roles"
  policy      = data.aws_iam_policy_document.boundary.json
}

# 2. Deploy role, assumed by IAM Identity Center (SSO) users and/or IAM principals
data "aws_iam_policy_document" "deployer_trust" {
  # SSO users signed in with one of the trusted permission sets. MFA is enforced
  # by Identity Center at sign-in.
  dynamic "statement" {
    for_each = length(local.sso_role_arns) > 0 ? [1] : []
    content {
      sid     = "SsoPermissionSets"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = local.sso_role_arns
      }
    }
  }

  # Explicit IAM users or roles
  dynamic "statement" {
    for_each = length(local.trusted_principal_arns) > 0 ? [1] : []
    content {
      sid     = "IamPrincipals"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = local.trusted_principal_arns
      }

      dynamic "condition" {
        for_each = var.require_mfa ? [1] : []
        content {
          test     = "Bool"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["true"]
        }
      }
    }
  }
}

resource "aws_iam_role" "deployer" {
  name                 = "${local.prefix}-deployer"
  description          = "Least-privilege role used by Terraform to deploy ${local.prefix}"
  assume_role_policy   = data.aws_iam_policy_document.deployer_trust.json
  max_session_duration = var.max_session_duration
}

# 3. Deploy policy: only what iac/env needs, scoped by name prefix and region
data "aws_iam_policy_document" "deployer" {
  statement {
    sid       = "Lambda"
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = [local.function_arn, "${local.function_arn}:*"]
  }

  statement {
    sid    = "LambdaRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:DetachRolePolicy",
    ]
    resources = [local.lambda_role_arn]
  }

  # Roles can only be created with the boundary attached
  statement {
    sid       = "CreateLambdaRolesWithBoundary"
    effect    = "Allow"
    actions   = ["iam:CreateRole"]
    resources = [local.lambda_role_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.boundary.arn]
    }
  }

  # Only the project's own policies can be attached
  statement {
    sid       = "AttachProjectPolicies"
    effect    = "Allow"
    actions   = ["iam:AttachRolePolicy"]
    resources = [local.lambda_role_arn]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values   = [local.lambda_policy_arn]
    }
  }

  statement {
    sid       = "PassRoleToLambda"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.lambda_role_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid    = "LambdaPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListPolicyTags",
    ]
    resources = [local.lambda_policy_arn]
  }

  statement {
    sid    = "LogGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "logs:ListTagsLogGroup",
    ]
    resources = [local.log_group_arn, "${local.log_group_arn}:*"]
  }

  statement {
    sid       = "DescribeLogGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  # API Gateway ARNs are ID-based, so region is the tightest practical scope
  statement {
    sid    = "ApiGateway"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
    ]
    resources = [
      "arn:${local.partition}:apigateway:${local.region}::/restapis",
      "arn:${local.partition}:apigateway:${local.region}::/restapis/*",
      "arn:${local.partition}:apigateway:${local.region}::/tags/*",
    ]
  }

  statement {
    sid       = "VerifyTeardown"
    effect    = "Allow"
    actions   = ["tag:GetResources"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyBoundaryRemoval"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenySelfModification"
    effect    = "Deny"
    actions   = ["iam:*"]
    resources = [local.deployer_role_arn, local.deployer_pol_arn, local.boundary_arn]
  }
}

resource "aws_iam_policy" "deployer" {
  name        = "${local.prefix}-deployer"
  description = "Least-privilege deploy permissions for ${local.prefix}"
  policy      = data.aws_iam_policy_document.deployer.json
}

resource "aws_iam_role_policy_attachment" "deployer" {
  role       = aws_iam_role.deployer.name
  policy_arn = aws_iam_policy.deployer.arn
}
