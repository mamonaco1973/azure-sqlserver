# =================================================================================
# Azure SQL Managed Instance
# Creates a private (no public endpoint) General Purpose MI on Gen5 hardware
# in the provided resource group/location and dedicated subnet.
# =================================================================================
resource "azurerm_mssql_managed_instance" "sql_mi" {
  # Resource naming: suffix ensures global uniqueness for MI name
  name = "sqlmi-${random_string.suffix.result}"

  # Placement
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location

  # Admin auth (use Key Vault in real deployments; avoid exposing secrets in state)
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sqlserver_password.result

  # Licensing & SKU
  license_type = "LicenseIncluded" # or "BasePrice" if using Azure Hybrid Benefit

  # Compute & service tier
  sku_name = "GP_Gen5" # General Purpose (GP) on Gen5 hardware; alt: "BC_Gen5" for Business Critical
  vcores   = 4         # CPU capacity; scale up/down impacts cost and performance

  # Storage (GP tier uses remote storage; BC uses local SSD)
  storage_size_in_gb = 64 # Increase for higher throughput/backup retention needs

  # Networking
  subnet_id = azurerm_subnet.sql_mi_subnet.id # must be a dedicated subnet sized /27 or larger

  # Security & connectivity
  public_data_endpoint_enabled = false                          # keep MI private; expose via private endpoints/peering if needed
  collation                    = "SQL_Latin1_General_CP1_CI_AS" # set to your org standard; changing later is non-trivial
  minimum_tls_version          = "1.2"                          # enforce TLS 1.2+ for client connections

  # Ensure NSG and route table are associated to the MI subnet before MI creation
  depends_on = [
    azurerm_subnet_network_security_group_association.sqlserver-mi-nsg-assoc,
    azurerm_subnet_route_table_association.sql_mi_rt_assoc
  ]
}
