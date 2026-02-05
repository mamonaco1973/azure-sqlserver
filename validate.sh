#!/bin/bash
# ================================================================================
# FILE: validate.sh
# ================================================================================
# Resolves and validates post-deployment endpoints for the SQL Server
# quick-start deployment.
#
# Outputs (SUMMARY):
#   - Adminer public URL
#   - Azure SQL Server FQDN
#   - Azure SQL Managed Instance FQDN (if present)
#
# Behavior:
#   - Fails immediately on error.
#   - Waits for Adminer to become reachable before returning success.
# ================================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on any command failure
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail


# ================================================================================
# RESOLVE ADMINER PUBLIC DNS NAME
# ================================================================================
ADMINER_DNS_NAME=$(az network public-ip show \
  --name adminer-vm-public-ip \
  --resource-group sqlserver-rg \
  --query "dnsSettings.fqdn" \
  --output tsv)

# Fail if Adminer DNS name is empty
if [[ -z "${ADMINER_DNS_NAME}" ]]; then
  echo "ERROR: Adminer DNS name could not be resolved."
  exit 1
fi

ADMINER_URL="http://${ADMINER_DNS_NAME}"

# echo "NOTE: Adminer endpoint resolved:"
# echo "  ${ADMINER_URL}"


# ================================================================================
# WAIT FOR ADMINER AVAILABILITY
# ================================================================================
echo "NOTE: Waiting for Adminer to become reachable..."

MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --fail "${ADMINER_URL}/adminer" >/dev/null; do
  if [ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: Adminer not reachable after ${MAX_ATTEMPTS} attempts."
    exit 1
  fi

  echo "WARNING: Adminer not reachable. Retrying in 30 seconds..."
  sleep 30
  ATTEMPT=$((ATTEMPT + 1))
done

echo "NOTE: Adminer is reachable."


# ================================================================================
# RESOLVE AZURE SQL SERVER FQDN
# ================================================================================
SQL_SERVER_DNS=$(az sql server list \
  --resource-group sqlserver-rg \
  --query "[?starts_with(name, 'sqlserver')].fullyQualifiedDomainName" \
  --output tsv)

if [[ -z "${SQL_SERVER_DNS}" ]]; then
  echo "ERROR: SQL Server DNS name could not be resolved."
  exit 1
fi


# ================================================================================
# RESOLVE AZURE SQL MANAGED INSTANCE FQDN (OPTIONAL)
# ================================================================================
MI_INSTANCE=$(az sql mi list \
  --resource-group sqlserver-rg \
  --query "[?starts_with(name, 'sqlmi')].name" \
  --output tsv)

SQL_MI_DNS=""

if [[ -n "${MI_INSTANCE}" ]]; then
  SQL_MI_DNS=$(az sql mi show \
    --name "${MI_INSTANCE}" \
    --resource-group sqlserver-rg \
    --query fullyQualifiedDomainName \
    --output tsv)
fi


# ================================================================================
# FINAL OUTPUT SUMMARY
# ================================================================================
echo ""
echo "======================================================================"
echo "BUILD VALIDATION COMPLETE"
echo "======================================================================"
echo "Adminer URL:"
echo "  ${ADMINER_URL}"
echo ""
echo "Azure SQL Server FQDN:"
echo "  ${SQL_SERVER_DNS}"

if [[ -n "${SQL_MI_DNS}" ]]; then
  echo ""
  echo "Azure SQL Managed Instance FQDN:"
  echo "  ${SQL_MI_DNS}"
fi

echo "======================================================================"


# ================================================================================
# END OF FILE
# ================================================================================
