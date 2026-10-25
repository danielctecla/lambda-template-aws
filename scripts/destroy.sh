#!/usr/bin/env bash
# Safely destroy the whole stack.
#
#   scripts/destroy.sh                   # destroy iac/env
#   scripts/destroy.sh --with-bootstrap  # also destroy the deploy role (iac/bootstrap)
#
# Uses your current AWS credentials (e.g. export AWS_PROFILE=<sso-profile>).
# Set EXPECTED_ACCOUNT_ID to abort if your credentials point to another account.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="$ROOT_DIR/iac/env"
BOOTSTRAP_DIR="$ROOT_DIR/iac/bootstrap"
PLAN_FILE="destroy.tfplan"

WITH_BOOTSTRAP=false
case "${1:-}" in
  "") ;;
  --with-bootstrap) WITH_BOOTSTRAP=true ;;
  *) echo "Usage: $0 [--with-bootstrap]" >&2; exit 1 ;;
esac

if [[ ! -t 0 ]]; then
  echo "Refusing to run without an interactive terminal (confirmation required)." >&2
  exit 1
fi

tf_var() {
  echo "var.$2" | terraform -chdir="$1" console 2>/dev/null | tr -d '"'
}

# Plan the destroy, show it, ask for the project name, apply exactly that plan
destroy_stack() {
  local dir="$1" name="$2"

  terraform -chdir="$dir" init -input=false >/dev/null

  if [[ -z "$(terraform -chdir="$dir" state list 2>/dev/null)" ]]; then
    echo "Nothing to destroy in ${dir#"$ROOT_DIR"/}."
    return
  fi

  terraform -chdir="$dir" plan -destroy -input=false -out="$PLAN_FILE"

  echo
  read -r -p "Type the project name ($name) to destroy ${dir#"$ROOT_DIR"/}: " answer
  if [[ "$answer" != "$name" ]]; then
    rm -f "$dir/$PLAN_FILE"
    echo "Aborted, nothing was destroyed." >&2
    exit 1
  fi

  terraform -chdir="$dir" apply -input=false "$PLAN_FILE"
  rm -f "$dir/$PLAN_FILE"

  if [[ -n "$(terraform -chdir="$dir" state list)" ]]; then
    echo "WARNING: resources remain in the state of ${dir#"$ROOT_DIR"/}." >&2
    exit 1
  fi
}

# 1. Check who we are and where we deploy
if ! identity="$(aws sts get-caller-identity --query '[Account, Arn]' --output text)"; then
  echo "No valid AWS credentials. Run: aws sso login --profile ${AWS_PROFILE:-<profile>}" >&2
  exit 1
fi
read -r account_id caller_arn <<<"$identity"
echo "Caller:  $caller_arn"

if [[ -n "${EXPECTED_ACCOUNT_ID:-}" && "$account_id" != "$EXPECTED_ACCOUNT_ID" ]]; then
  echo "Account $account_id does not match EXPECTED_ACCOUNT_ID. Aborting." >&2
  exit 1
fi

terraform -chdir="$ENV_DIR" init -input=false >/dev/null
project_name="$(tf_var "$ENV_DIR" project_name)"
region="$(tf_var "$ENV_DIR" aws_region)"
echo "Project: $project_name"
echo "Region:  $region"
echo

# 2. Destroy the main stack
destroy_stack "$ENV_DIR" "$project_name"

# 3. Verify nothing tagged with the project is left
leftover="$(aws resourcegroupstaggingapi get-resources --region "$region" \
  --tag-filters "Key=Project,Values=$project_name" \
  --query 'ResourceTagMappingList[].ResourceARN' --output text)"
leftover_roles="$(aws iam list-roles \
  --query "Roles[?starts_with(RoleName, '$project_name-') && ends_with(RoleName, '-role')].RoleName" \
  --output text)"

if [[ -n "$leftover" || -n "$leftover_roles" ]]; then
  echo "WARNING: resources still found (the tagging API can lag a few minutes):" >&2
  printf '%s\n' $leftover $leftover_roles >&2
else
  echo "Main stack destroyed, no leftover resources found."
fi

# 4. Optionally remove the deploy role and boundary
if [[ "$WITH_BOOTSTRAP" == true ]]; then
  echo
  destroy_stack "$BOOTSTRAP_DIR" "$project_name"
  echo "Bootstrap destroyed."
fi
