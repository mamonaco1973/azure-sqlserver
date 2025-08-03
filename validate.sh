#!/bin/bash

#-------------------------------------------------------------------------------
# Output adminer URL and SQL Server DNS name
#-------------------------------------------------------------------------------

ADMINER_DNS_NAME=$(az network public-ip show \
   --name adminer-vm-public-ip \
   --resource-group sqlserver-rg \
   --query "dnsSettings.fqdn" \
   --output tsv)

echo "NOTE: Adminer running at http://$ADMINER_DNS_NAME"

# Wait until the adminer URL is reachable (HTTP 200 or similar)
echo "NOTE: Waiting for adminer to become available at http://$ADMINER_DNS_NAME..."

# Max attempts (optional)
MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --fail "http://$ADMINER_DNS_NAME" > /dev/null; do
   if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
     echo "ERROR: Adminer did not become available after $MAX_ATTEMPTS attempts."
     exit 1
   fi
   echo "WARNING: Adminer not yet reachable. Retrying in 30 seconds..."
   sleep 30
   ATTEMPT=$((ATTEMPT+1))
done

SQL_SERVER_DNS=$(az sql server list --resource-group sqlserver-rg \
     --query "[?starts_with(name, 'sqlserver')].fullyQualifiedDomainName" \
     -o tsv)

echo "NOTE: Hostname for SQL Server is \"$SQL_SERVER_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
