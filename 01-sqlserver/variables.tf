# ================================================================================
# INPUT VARIABLES: PROJECT SETTINGS
# ================================================================================
# Defines the core project inputs used to name and place Azure resources.
#
# Conventions:
#   - Defaults are suitable for quick-start deployments.
#   - Override via *.tfvars or -var flags for multi-env usage.
# ================================================================================


# ------------------------------------------------------------------------------
# PROJECT RESOURCE GROUP
# ------------------------------------------------------------------------------
# Container resource for all deployed Azure resources in this stack.
# ------------------------------------------------------------------------------
variable "project_resource_group" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "sqlserver-rg"
}


# ------------------------------------------------------------------------------
# PROJECT VIRTUAL NETWORK (VNET)
# ------------------------------------------------------------------------------
# Logical network boundary for all subnets and private endpoints.
# ------------------------------------------------------------------------------
variable "project_vnet" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "sqlserver-vnet"
}


# ------------------------------------------------------------------------------
# PROJECT SUBNET (SQL SERVER / PRIVATE ENDPOINT SUBNET)
# ------------------------------------------------------------------------------
# Subnet used by SQL Server-related resources (e.g., Private Endpoint).
#
# NOTE:
#   VM subnet and SQL MI subnet are defined separately to keep roles isolated.
# ------------------------------------------------------------------------------
variable "project_subnet" {
  description = "Name of the Azure Subnet within the Virtual Network"
  type        = string
  default     = "sqlserver-subnet"
}


# ------------------------------------------------------------------------------
# PROJECT LOCATION / REGION
# ------------------------------------------------------------------------------
# Azure region where all resources will be deployed.
#
# NOTE:
#   AzureRM accepts region strings like "Central US" or "eastus" depending
#   on API surface. Keep this value consistent across your stack.
# ------------------------------------------------------------------------------
variable "project_location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "Central US"
}
