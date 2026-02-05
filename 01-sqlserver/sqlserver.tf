# ================================================================================
# RANDOM SUFFIX: RESOURCE NAME UNIQUENESS
# ================================================================================
# Generates a short numeric suffix used to avoid name collisions for
# globally-unique Azure resource names (e.g., SQL Server).
# ================================================================================
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}


# ================================================================================
# PRIVATE DNS ZONE: AZURE SQL SERVER PRIVATE LINK
# ================================================================================
# Creates the Private DNS zone used by Azure Private Link for Azure SQL
# Server. Resources in the linked VNet will resolve SQL Server FQDNs to
# private IPs.
# ================================================================================
resource "azurerm_private_dns_zone" "sql_private_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.project_rg.name
}


# ================================================================================
# PRIVATE DNS LINK: VNET ASSOCIATION
# ================================================================================
# Links the Private DNS zone to the project VNet so VMs and services
# inside the VNet can resolve Private Link records.
# ================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.project_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns.name
  virtual_network_id    = azurerm_virtual_network.project-vnet.id
}


# ================================================================================
# AZURE SQL SERVER: LOGICAL SERVER
# ================================================================================
# Creates an Azure SQL logical server with public network access disabled.
#
# Notes:
#   - Connectivity is provided through a Private Endpoint.
#   - Admin credentials should be sourced from Key Vault for real stacks.
# ================================================================================
resource "azurerm_mssql_server" "sql_server_instance" {
  name                          = "sqlserver-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.project_rg.name
  location                      = azurerm_resource_group.project_rg.location
  version                       = "12.0"
  administrator_login           = "sqladmin"
  administrator_login_password  = random_password.sqlserver_password.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
}


# ================================================================================
# PRIVATE ENDPOINT: AZURE SQL SERVER
# ================================================================================
# Creates a Private Endpoint in the SQL Server subnet for the Azure SQL
# logical server, enabling private connectivity from within the VNet.
# ================================================================================
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "sqlserver-pe"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  subnet_id           = azurerm_subnet.sqlserver-subnet.id

  private_service_connection {
    name                           = "sqlserver-privateservice"
    private_connection_resource_id = azurerm_mssql_server.sql_server_instance.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}


# ================================================================================
# PRIVATE DNS: A RECORD FOR SQL SERVER PRIVATE ENDPOINT
# ================================================================================
# Creates an A record in the Private DNS zone mapping the SQL Server name
# to the Private Endpoint IP address.
#
# NOTE:
#   In many architectures this is commonly handled via a DNS zone group.
#   This explicit record is acceptable for simple stacks.
# ================================================================================
resource "azurerm_private_dns_a_record" "sql_dns_record" {
  name                = azurerm_mssql_server.sql_server_instance.name
  zone_name           = azurerm_private_dns_zone.sql_private_dns.name
  resource_group_name = azurerm_resource_group.project_rg.name
  ttl                 = 300

  records = [
    azurerm_private_endpoint.sql_private_endpoint
    .private_service_connection[0]
    .private_ip_address
  ]
}
