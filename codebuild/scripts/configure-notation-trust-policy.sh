#!/usr/bin/env bash
set -euo pipefail

AWS_ACCOUNT_ID="${1:?AWS account ID is required}"
AWS_REGION="${2:?AWS region is required}"
ECR_REPOSITORY="${3:?ECR repository is required}"
SIGNING_PROFILE_NAME="${4:?AWS Signer signing profile name is required}"

REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
REGISTRY_SCOPE="${REGISTRY}/${ECR_REPOSITORY}"
SIGNING_PROFILE_ARN="arn:aws:signer:${AWS_REGION}:${AWS_ACCOUNT_ID}:/signing-profiles/${SIGNING_PROFILE_NAME}"
NOTATION_CONFIG_DIR="${NOTATION_CONFIG:-${HOME}/.config/notation}"
TRUST_POLICY_FILE="${NOTATION_CONFIG_DIR}/trustpolicy.oci.json"

mkdir -p "${NOTATION_CONFIG_DIR}"

cat > "${TRUST_POLICY_FILE}" <<JSON
{
  "version": "1.0",
  "trustPolicies": [
    {
      "name": "jjp6402-aws-signer",
      "registryScopes": [
        "${REGISTRY_SCOPE}"
      ],
      "signatureVerification": {
        "level": "strict"
      },
      "trustStores": [
        "signingAuthority:aws-signer-ts"
      ],
      "trustedIdentities": [
        "${SIGNING_PROFILE_ARN}"
      ]
    }
  ]
}
JSON

# Backward compatibility for Notation clients that still look for trustpolicy.json.
cp "${TRUST_POLICY_FILE}" "${NOTATION_CONFIG_DIR}/trustpolicy.json"

notation policy show
