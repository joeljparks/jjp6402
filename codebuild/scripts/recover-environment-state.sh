#!/usr/bin/env bash
set -euo pipefail

NAME_PREFIX="${NAME_PREFIX:-jjp6402}"

is_managed() {
  terraform state show "$1" >/dev/null 2>&1
}

import_if_exists() {
  local address="$1"
  local import_id="$2"
  local check_cmd="$3"

  if is_managed "$address"; then
    echo "Terraform already manages ${address}."
    return 0
  fi

  if eval "$check_cmd" >/dev/null 2>&1; then
    echo "Importing existing ${address} into Terraform state."
    terraform import -input=false "$address" "$import_id"
    terraform state show "$address" >/dev/null
  else
    echo "No existing resource found for ${address}."
  fi
}

import_if_exists \
  "module.iam.aws_iam_instance_profile.mongodb" \
  "${NAME_PREFIX}-mongodb-profile" \
  "aws iam get-instance-profile --instance-profile-name ${NAME_PREFIX}-mongodb-profile"

import_if_exists \
  "module.iam.aws_iam_role.mongodb" \
  "${NAME_PREFIX}-mongodb-role" \
  "aws iam get-role --role-name ${NAME_PREFIX}-mongodb-role"

if aws iam get-role-policy --role-name "${NAME_PREFIX}-mongodb-role" --policy-name "${NAME_PREFIX}-mongodb-permissive-policy" >/dev/null 2>&1; then
  if ! is_managed "module.iam.aws_iam_role_policy.mongodb_permissive"; then
    echo "Importing existing MongoDB permissive role policy into Terraform state."
    terraform import -input=false \
      "module.iam.aws_iam_role_policy.mongodb_permissive" \
      "${NAME_PREFIX}-mongodb-role:${NAME_PREFIX}-mongodb-permissive-policy"
  else
    echo "Terraform already manages module.iam.aws_iam_role_policy.mongodb_permissive."
  fi
else
  echo "No existing MongoDB permissive role policy found."
fi
