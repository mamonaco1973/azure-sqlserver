# ================================================================================
# AZURE SQL MANAGED INSTANCE: SQL_MI
# ================================================================================
# Provisions an Azure SQL Managed Instance (MI) in a dedicated subnet.
#
# Characteristics:
#   - General Purpose (GP) tier on Gen5 hardware
#   - Private-only (no public data endpoint)
#   - TLS 1.2 enforced for client connections
#
# Notes:
#   - Store administrator credentials in Key Vault for real deployments.
#   - The MI subnet should be dedicated and sized appropriately (commonly
#     /27 or larger). See Microsoft requirements for current guidance.
# ================================================================================
resource "azurerm_mssql_managed_instance" "sql_mi" {
  # ------------------------------------------------------------------------------
  # RESOURCE IDENTITY
  # ------------------------------------------------------------------------------
  name = "sqlmi-${random_string.suffix.result}" # Suffix ensures name uniqueness

  # ------------------------------------------------------------------------------
  # PLACEMENT
  # ------------------------------------------------------------------------------
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location

  # ------------------------------------------------------------------------------
  # ADMIN AUTHENTICATION
  # ------------------------------------------------------------------------------
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sqlserver_password.result

  # ------------------------------------------------------------------------------
  # LICENSING
  # ------------------------------------------------------------------------------
  license_type = "LicenseIncluded" # Use "BasePrice" for Azure Hybrid Benefit

  # ------------------------------------------------------------------------------
  # COMPUTE / SKU
  # ------------------------------------------------------------------------------
  sku_name = "GP_Gen5" # Alt: "BC_Gen5" for Business Critical
  vcores   = 4         # Scale impacts cost and performance

  # ------------------------------------------------------------------------------
  # STORAGE
  # ------------------------------------------------------------------------------
  storage_size_in_gb = 64 # Increase for throughput and retention needs

  # ------------------------------------------------------------------------------
  # NETWORKING
  # ------------------------------------------------------------------------------
  subnet_id = azurerm_subnet.sql_mi_subnet.id # Dedicated MI subnet

  # ------------------------------------------------------------------------------
  # SECURITY / CONNECTIVITY
  # ------------------------------------------------------------------------------
  public_data_endpoint_enabled = false
  collation                    = "SQL_Latin1_General_CP1_CI_AS"
  minimum_tls_version          = "1.2"

  # ------------------------------------------------------------------------------
  # DEPENDENCIES
  # ------------------------------------------------------------------------------
  # Ensure the MI subnet has its NSG and route table attached before MI creation.
  depends_on = [
    azurerm_subnet_network_security_group_association.sqlserver-mi-nsg-assoc,
    azurerm_subnet_route_table_association.sql_mi_rt_assoc
  ]
}
