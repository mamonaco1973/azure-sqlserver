# # -------------------------------------------------
# # PostgreSQL Flexible Server
# # -------------------------------------------------
# resource "azurerm_postgresql_flexible_server" "public_instance" {
#   name                          = "${random_string.suffix.result}-postgres-instance"
#   resource_group_name           = azurerm_resource_group.project_rg.name
#   location                      = azurerm_resource_group.project_rg.location
#   version                       = "15"
#   administrator_login           = "postgres"
#   administrator_password        = random_password.postgres_password.result
#   private_dns_zone_id           = null
#   storage_mb                    = 32768
#   sku_name                      = "B_Standard_B1ms"
#   backup_retention_days         = 7
#   geo_redundant_backup_enabled  = false
#   public_network_access_enabled = true
#   zone                          = "1"
# }

# resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_my_ip" {
#   name             = "AllowAllIPs"
#   server_id        = azurerm_postgresql_flexible_server.public_instance.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "255.255.255.255"
# }

# =================================================================================
# CREATE PRIVATE DNS ZONE FOR POSTGRES FLEXIBLE SERVER
# =================================================================================
resource "azurerm_private_dns_zone" "postgres_private_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================q
# LINK PRIVATE DNS ZONE TO VNET
# =================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "postgres-dns-link"
  resource_group_name   = azurerm_resource_group.project_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_private_dns.name
  virtual_network_id    = azurerm_virtual_network.project-vnet.id
}

# =================================================================================
# CREATE PRIVATE POSTGRESQL FLEXIBLE SERVER
# =================================================================================
resource "azurerm_postgresql_flexible_server" "postgres_instance" {
  name                          = "postgres-instance-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.project_rg.name
  location                      = azurerm_resource_group.project_rg.location
  version                       = "15"
  administrator_login           = "postgres"
  administrator_password        = random_password.postgres_password.result
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  zone                          = "1"
  public_network_access_enabled = false

  # Ensure PostgreSQL is deployed into a delegated subnet
  delegated_subnet_id = azurerm_subnet.postgres-subnet.id

  # Link to the private DNS zone
  private_dns_zone_id = azurerm_private_dns_zone.postgres_private_dns.id
}
