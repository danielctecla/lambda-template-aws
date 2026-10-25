provider "aws" {
  region = var.aws_region

  # Deploy with short-lived credentials from the bootstrap role, when set
  dynamic "assume_role" {
    for_each = var.deploy_role_arn == null ? [] : [1]
    content {
      role_arn     = var.deploy_role_arn
      session_name = "${var.project_name}-terraform"
    }
  }

  default_tags {
    tags = merge(var.tags, {
      Project   = var.project_name
      ManagedBy = "terraform"
    })
  }
}
