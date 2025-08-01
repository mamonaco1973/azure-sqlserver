#!/bin/bash

#-------------------------------------------------------------------------------
# Output pgweb URL and postgres DNS name
#-------------------------------------------------------------------------------

PGWEB_DNS_NAME=$(az network public-ip show \
  --name pgweb-vm-public-ip \
  --resource-group postgres-rg \
  --query "dnsSettings.fqdn" \
  --output tsv)

echo "NOTE: pgweb running at http://$PGWEB_DNS_NAME"

# Wait until the pgweb URL is reachable (HTTP 200 or similar)
echo "NOTE: Waiting for pgweb to become available at http://$PGWEB_DNS_NAME ..."

# Max attempts (optional)
MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --fail "http://$PGWEB_DNS_NAME" > /dev/null; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: pgweb did not become available after $MAX_ATTEMPTS attempts."
    exit 1
  fi
  echo "WARNING: pgweb not yet reachable. Retrying in 30 seconds..."
  sleep 30
  ATTEMPT=$((ATTEMPT+1))
done

PG_DNS=$(az postgres flexible-server list \
  --resource-group postgres-rg \
  --query "[?starts_with(name, 'postgres-instance')].fullyQualifiedDomainName" \
  --output tsv)

echo "NOTE: Hostname for postgres server is \"$PG_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
