# =================================================================================
# CREATE SQL MANAGED INSTANCE
# =================================================================================
resource "azurerm_mssql_managed_instance" "sql_mi" {
  name                         = "sqlmi-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.project_rg.name
  location                     = azurerm_resource_group.project_rg.location
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sqlserver_password.result
  license_type                 = "LicenseIncluded"
  sku_name                     = "GP_Gen5" # General Purpose, Gen5 hardware
  vcores                       = 4
  storage_size_in_gb           = 64
  subnet_id                    = azurerm_subnet.sql_mi_subnet.id
  public_data_endpoint_enabled = false
  collation                    = "SQL_Latin1_General_CP1_CI_AS"
  minimum_tls_version          = "1.2"
}
