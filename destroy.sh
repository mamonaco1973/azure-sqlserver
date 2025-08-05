#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 1: Destroy sqlserver infrastructure (VNet, Subnet, NICs, NSGs, etc.)
#-------------------------------------------------------------------------------
cd 01-sqlserver                    # Go to base infra config
terraform init                     # Initialize Terraform plugins/modules
terraform destroy -target=azurerm_mssql_managed_instance.sql_mi -auto-approve 
terraform destroy -auto-approve    # Destroy all foundational Azure resources
cd ..                              # Return to root

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
