#!/bin/bash
# ================================================================================
# FILE: check_env.sh
# ================================================================================
# Validates that all required tools and environment variables are present
# before running any Terraform or Azure provisioning steps.
#
# This script also authenticates to Azure using a Service Principal.
#
# Behavior:
#   - Exits immediately on any failure.
#   - Intended to be run by apply.sh before infrastructure deployment.
# ================================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on any command failure
#   -u  Treat unset variables as errors
#   -o pipefail  Fail if any command in a pipeline fails
set -euo pipefail


# ================================================================================
# VALIDATE REQUIRED COMMANDS
# ================================================================================
echo "NOTE: Validating that required commands are found in PATH."

# List of required CLI tools
commands=("az" "terraform" "jq")

# Track overall command availability
all_found=true

# Check each command exists in PATH
for cmd in "${commands[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: ${cmd} is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: ${cmd} is found in the current PATH."
  fi
done

# Fail if any required command is missing
if [ "${all_found}" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more required commands are missing."
  exit 1
fi


# ================================================================================
# VALIDATE REQUIRED ENVIRONMENT VARIABLES
# ================================================================================
echo "NOTE: Validating that required environment variables are set."

# Azure Service Principal variables required by AzureRM provider
required_vars=(
  "ARM_CLIENT_ID"
  "ARM_CLIENT_SECRET"
  "ARM_SUBSCRIPTION_ID"
  "ARM_TENANT_ID"
)

# Track overall variable availability
all_set=true

# Check each required variable is set and non-empty
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: ${var} is not set or is empty."
    all_set=false
  else
    echo "NOTE: ${var} is set."
  fi
done

# Fail if any required variable is missing
if [ "${all_set}" = true ]; then
  echo "NOTE: All required environment variables are set."
else
  echo "ERROR: One or more required environment variables are missing."
  exit 1
fi


# ================================================================================
# AZURE AUTHENTICATION
# ================================================================================
# Authenticate to Azure using a Service Principal.
#
# Output is suppressed to avoid leaking credentials to logs.
# ================================================================================
echo "NOTE: Logging in to Azure using Service Principal..."

az login \
  --service-principal \
  --username "${ARM_CLIENT_ID}" \
  --password "${ARM_CLIENT_SECRET}" \
  --tenant "${ARM_TENANT_ID}" \
  >/dev/null 2>&1

echo "NOTE: Successfully logged into Azure."


# ================================================================================
# END OF FILE
# ================================================================================
