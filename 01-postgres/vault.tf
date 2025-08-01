# =================================================================================
# GENERATE RANDOM SUFFIX FOR UNIQUE KEY VAULT NAME
# =================================================================================
resource "random_string" "key_vault_suffix" {
  length  = 8     # Create an 8-character string for uniqueness
  special = false # Exclude special characters to ensure DNS-compliant names
  upper   = false # Lowercase only (safe for Azure naming conventions)
  # Final output will be appended to the Key Vault name
}

# =================================================================================
# DEPLOY A CENTRALIZED AZURE KEY VAULT FOR SECRETS MANAGEMENT
# =================================================================================
resource "azurerm_key_vault" "credentials_key_vault" {
  name                      = "creds-kv-${random_string.key_vault_suffix.result}" # Unique Key Vault name
  resource_group_name       = azurerm_resource_group.project_rg.name              # Place Key Vault in target resource group
  location                  = var.project_location                                # Use the same Azure region
  sku_name                  = "standard"                                          # Standard SKU for general-purpose secrets
  tenant_id                 = data.azurerm_client_config.current.tenant_id        # Azure AD tenant of the current user
  purge_protection_enabled  = false                                               # Allow permanent deletion
  enable_rbac_authorization = true                                                # Enable RBAC (preferred over legacy Access Policies)
}

# =================================================================================
# ASSIGN "Key Vault Secrets Officer" ROLE TO CURRENT USER OR SERVICE PRINCIPAL
# =================================================================================
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.credentials_key_vault.id   # Limit scope to the Key Vault
  role_definition_name = "Key Vault Secrets Officer"                  # Grant permissions for managing secrets only
  principal_id         = data.azurerm_client_config.current.object_id # Target: currently logged-in user or service principal
}

# =================================================================================
# CREATE A STRONG RANDOM PASSWORD FOR DATABASE LOGIN
# =================================================================================
resource "random_password" "postgres_password" {
  length  = 24    # 24 characters for strong entropy
  special = false # Avoid special chars (e.g., for scripts or connection strings)
}

# =================================================================================
# SAVE POSTGRES CREDENTIALS AS A JSON-ENCODED SECRET IN KEY VAULT
# =================================================================================
resource "azurerm_key_vault_secret" "postgres_secret" {
  name = "postgres-credentials" # Logical name of the secret
  value = jsonencode({          # JSON-encoded username + password
    username = "postgres"
    password = random_password.postgres_password.result
  })
  key_vault_id = azurerm_key_vault.credentials_key_vault.id   # Target Key Vault ID
  depends_on   = [azurerm_role_assignment.kv_role_assignment] # Ensure access is granted before creating secret
  content_type = "application/json"                           # Tag content format for metadata clarity
}

# =================================================================================
# CREATE A STRONG RANDOM PASSWORD FOR VM LOGIN
# =================================================================================
resource "random_password" "vm_password" {
  length  = 24    # 24 characters for strong entropy
  special = false # Avoid special chars (e.g., for scripts or connection strings)
}

# =================================================================================
# SAVE VM CREDENTIALS AS A JSON-ENCODED SECRET IN KEY VAULT
# =================================================================================
resource "azurerm_key_vault_secret" "vm_secret" {
  name = "vm-credentials" # Logical name of the secret
  value = jsonencode({    # JSON-encoded username + password
    username = "sysadmin"
    password = random_password.vm_password.result
  })
  key_vault_id = azurerm_key_vault.credentials_key_vault.id   # Target Key Vault ID
  depends_on   = [azurerm_role_assignment.kv_role_assignment] # Ensure access is granted before creating secret
  content_type = "application/json"                           # Tag content format for metadata clarity
}