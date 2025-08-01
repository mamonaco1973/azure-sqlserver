# -------------------------------------------------------------------------------------------------
# DEFINE THE NAME OF THE AZURE RESOURCE GROUP
# -------------------------------------------------------------------------------------------------
variable "project_resource_group" {
  description = "Name of the Azure Resource Group" # This is the container for all resources
  default     = "postgres-rg"                      # Default RG name unless overridden
  type        = string                             # Must be a string (no lists, no objects)
}

# -------------------------------------------------------------------------------------------------
# DEFINE THE NAME OF THE VIRTUAL NETWORK (VNET)
# -------------------------------------------------------------------------------------------------
variable "project_vnet" {
  description = "Name of the Azure Virtual Network" # The logical network space for your project
  default     = "postgres-vnet"                     # Default name — can be overridden via CLI/TFVars
  type        = string
}

# -------------------------------------------------------------------------------------------------
# DEFINE THE NAME OF THE SUBNET INSIDE THE VNET
# -------------------------------------------------------------------------------------------------
variable "project_subnet" {
  description = "Name of the Azure Subnet within the Virtual Network" # Subdivision of the VNet where VMs live
  default     = "postgres-subnet"                                     # Keep separate from Bastion subnet
  type        = string
}

# -------------------------------------------------------------------------------------------------
# DEFINE THE AZURE REGION FOR RESOURCE DEPLOYMENT
# -------------------------------------------------------------------------------------------------
variable "project_location" {
  description = "Azure region where resources will be deployed (e.g., eastus, westeurope)" # Must match available Azure regions
  default     = "Central US"                                                               # Change this if deploying in a different region
  type        = string
}
