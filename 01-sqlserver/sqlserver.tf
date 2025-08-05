resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

# # =================================================================================
# # CREATE PRIVATE DNS ZONE FOR AZURE SQL SERVER
# # =================================================================================
# resource "azurerm_private_dns_zone" "sql_private_dns" {
#   name                = "privatelink.database.windows.net"
#   resource_group_name = azurerm_resource_group.project_rg.name
# }

# # =================================================================================
# # LINK PRIVATE DNS ZONE TO VNET
# # =================================================================================
# resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
#   name                  = "sql-dns-link"
#   resource_group_name   = azurerm_resource_group.project_rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns.name
#   virtual_network_id    = azurerm_virtual_network.project-vnet.id
#}

# =================================================================================
# CREATE AZURE SQL SERVER
# =================================================================================
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

# # =================================================================================
# # CREATE PRIVATE ENDPOINT FOR SQL SERVER
# # =================================================================================
# resource "azurerm_private_endpoint" "sql_private_endpoint" {
#   name                = "sqlserver-pe"
#   location            = azurerm_resource_group.project_rg.location
#   resource_group_name = azurerm_resource_group.project_rg.name
#   subnet_id           = azurerm_subnet.sqlserver-subnet.id

#   private_service_connection {
#     name                           = "sqlserver-privateservice"
#     private_connection_resource_id = azurerm_mssql_server.sql_server_instance.id
#     subresource_names              = ["sqlServer"]
#     is_manual_connection           = false
#   }
# }

# # =================================================================================
# # LINK PRIVATE ENDPOINT TO PRIVATE DNS ZONE
# # =================================================================================
# resource "azurerm_private_dns_a_record" "sql_dns_record" {
#   name                = azurerm_mssql_server.sql_server_instance.name
#   zone_name           = azurerm_private_dns_zone.sql_private_dns.name
#   resource_group_name = azurerm_resource_group.project_rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.sql_private_endpoint.private_service_connection[0].private_ip_address]
# }
