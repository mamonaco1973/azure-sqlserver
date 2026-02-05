#!/bin/bash
# ================================================================================
# FILE: destroy.sh
# ================================================================================
# Destroys all Azure resources provisioned by this project.
#
# Behavior:
#   - Fails immediately on any error.
#   - Explicitly destroys the SQL Managed Instance first to avoid
#     dependency and ordering issues.
#
# WARNING:
#   - This operation is destructive and cannot be undone.
#   - All data stored in Azure resources will be permanently deleted.
# ================================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on any command failure
#   -u  Treat unset variables as errors
#   -o pipefail  Fail if any command in a pipeline fails
set -euo pipefail


# ================================================================================
# STEP 1: DESTROY SQL SERVER INFRASTRUCTURE
# ================================================================================
# Terraform destruction is performed in two phases:
#   1. Explicitly destroy the SQL Managed Instance.
#   2. Destroy all remaining infrastructure resources.
#
# This ordering helps avoid dependency-related failures during teardown.
# ================================================================================
cd 01-sqlserver

terraform init

terraform destroy \
  -target=azurerm_mssql_managed_instance.sql_mi \
  -auto-approve

terraform destroy -auto-approve

cd ..


# ================================================================================
# END OF FILE
# ================================================================================
