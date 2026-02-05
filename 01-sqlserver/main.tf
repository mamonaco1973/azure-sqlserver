# ================================================================================
# PROVIDER: AZURERM
# ================================================================================
# Configures the AzureRM provider used to interact with Azure resources.
#
# Notes:
#   - The features block is mandatory, even if left empty.
#   - Removing this block will cause provider initialization to fail.
# ================================================================================
provider "azurerm" {
  features {}
}


# ================================================================================
# DATA SOURCE: AZURE SUBSCRIPTION
# ================================================================================
# Retrieves metadata about the currently selected Azure subscription.
#
# Exposed attributes:
#   - subscription_id
#   - display_name
#   - tenant_id
#
# Common use cases:
#   - Resource tagging
#   - Cross-subscription logic
#   - Tenant-scoped configuration
# ================================================================================
data "azurerm_subscription" "primary" {}


# ================================================================================
# DATA SOURCE: AZURE CLIENT CONFIGURATION
# ================================================================================
# Retrieves authentication context for the active Azure identity.
#
# This reflects the currently authenticated Azure CLI user or
# service principal.
#
# Exposed attributes:
#   - client_id
#   - object_id
#   - tenant_id
#
# Common use cases:
#   - Role assignments
#   - Managed identity bindings
#   - Secure access control configuration
# ================================================================================
data "azurerm_client_config" "current" {}


# ================================================================================
# RESOURCE GROUP: PROJECT ROOT
# ================================================================================
# Creates the primary resource group that acts as the logical container
# for all infrastructure deployed by this project.
#
# All Azure resources in this stack should be scoped to this group.
# ================================================================================
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group
  location = var.project_location
}
