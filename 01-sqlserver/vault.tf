# ================================================================================
# RANDOM SUFFIX: KEY VAULT NAME UNIQUENESS
# ================================================================================
# Generates a lowercase, DNS-safe suffix to ensure the Key Vault name
# is globally unique within Azure.
# ================================================================================
resource "random_string" "key_vault_suffix" {
  length  = 8
  special = false
  upper   = false
}


# ================================================================================
# KEY VAULT: CENTRALIZED SECRETS MANAGEMENT
# ================================================================================
# Deploys an Azure Key Vault used to store credentials and other sensitive
# values required by this deployment.
#
# Notes:
#   - RBAC authorization is enabled (preferred over access policies).
#   - Purge protection is disabled for quick-start / demo workflows.
# ================================================================================
resource "azurerm_key_vault" "credentials_key_vault" {
  name                       = "creds-kv-${random_string.key_vault_suffix.result}"
  resource_group_name        = azurerm_resource_group.project_rg.name
  location                   = var.project_location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
}


# ================================================================================
# ROLE ASSIGNMENT: KEY VAULT SECRETS OFFICER
# ================================================================================
# Grants the current user or service principal permissions to create and
# manage secrets in the Key Vault.
# ================================================================================
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.credentials_key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# ================================================================================
# RANDOM PASSWORD: SQL SERVER ADMIN
# ================================================================================
# Generates a strong password for the SQL Server administrator account.
# ================================================================================
resource "random_password" "sqlserver_password" {
  length  = 24
  special = false
}


# ================================================================================
# KEY VAULT SECRET: SQL SERVER CREDENTIALS
# ================================================================================
# Stores SQL Server administrator credentials as a JSON-encoded secret.
#
# Dependency:
#   - Requires RBAC role assignment before secret creation.
# ================================================================================
resource "azurerm_key_vault_secret" "sqlserver_secret" {
  name = "sqlserver-credentials"

  value = jsonencode({
    username = "sqladmin"
    password = random_password.sqlserver_password.result
  })

  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}


# ================================================================================
# RANDOM PASSWORD: VM ADMIN
# ================================================================================
# Generates a strong password for the VM administrator account.
# ================================================================================
resource "random_password" "vm_password" {
  length  = 24
  special = false
}


# ================================================================================
# KEY VAULT SECRET: VM CREDENTIALS
# ================================================================================
# Stores VM administrator credentials as a JSON-encoded secret.
#
# Dependency:
#   - Requires RBAC role assignment before secret creation.
# ================================================================================
resource "azurerm_key_vault_secret" "vm_secret" {
  name = "vm-credentials"

  value = jsonencode({
    username = "sysadmin"
    password = random_password.vm_password.result
  })

  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}
