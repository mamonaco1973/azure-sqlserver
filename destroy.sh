#!/bin/bash

MI_INSTANCE=$(az sql mi list \
  --resource-group sqlserver-rg \
  --query "[?starts_with(name, 'sqlmi')].name" \
  --output tsv)

if [ -n "$MI_INSTANCE" ]; then
  echo "NOTE: Deleting Managed Instance: $MI_INSTANCE"
  az sql mi delete \
    --name "$MI_INSTANCE" \
    --resource-group sqlserver-rg \
    --yes
else
  echo "WARNING: No Managed Instance found starting with 'sqlmi'. Skipping deletion."
fi


#-------------------------------------------------------------------------------
# STEP 1: Destroy sqlserver infrastructure (VNet, Subnet, NICs, NSGs, etc.)
#-------------------------------------------------------------------------------
cd 01-sqlserver                    # Go to base infra config
terraform init                     # Initialize Terraform plugins/modules
terraform destroy -auto-approve    # Destroy all foundational Azure resources
cd ..                              # Return to root

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
