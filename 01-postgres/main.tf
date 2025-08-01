
# =================================================================================
# CONFIGURE THE AZURERM PROVIDER TO INTERACT WITH AZURE RESOURCES
# =================================================================================
provider "azurerm" {
  features {} # Required block to enable AzureRM features; must be included even if empty
  # Do NOT remove this block — it's mandatory for provider initialization
}

# =================================================================================
# FETCH DETAILS ABOUT THE CURRENT AZURE SUBSCRIPTION
# =================================================================================
data "azurerm_subscription" "primary" {}
# Returns subscription_id, display_name, and tenant_id
# Useful for tagging, cross-subscription logic, or referencing tenant scope

# =================================================================================
# FETCH AUTH CONTEXT FOR CURRENT AZURE CLI OR SERVICE PRINCIPAL
# =================================================================================
data "azurerm_client_config" "current" {}
# Returns object_id, client_id, tenant_id of the currently authenticated principal
# Essential for assigning roles, linking managed identities, and securing resources

# =================================================================================
# CREATE THE PRIMARY RESOURCE GROUP FOR ALL DEPLOYED RESOURCES
# =================================================================================
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group # Name for the resource group (from input variable)
  location = var.project_location       # Azure region to deploy into (from input variable)
  # This group will act as the logical container for all related infrastructure
}
