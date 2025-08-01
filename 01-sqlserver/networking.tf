# =================================================================================
# CREATE A VIRTUAL NETWORK (VNET) TO HOST ALL SUBNETS
# =================================================================================
resource "azurerm_virtual_network" "project-vnet" {
  name                = var.project_vnet                       # VNet name (from input variable)
  address_space       = ["10.0.0.0/23"]                        # VNet CIDR range (512 IPs total)
  location            = var.project_location                   # Azure region (from variable)
  resource_group_name = azurerm_resource_group.project_rg.name # Resource group for the VNet
}

# =================================================================================
# DEFINE SUBNET FOR SQL SERVER FLEXIBLE SERVER
# =================================================================================
resource "azurerm_subnet" "sqlserver-subnet" {
  name                 = var.project_subnet                        # Subnet name (from variable)
  resource_group_name  = azurerm_resource_group.project_rg.name    # Must match VNet's RG
  virtual_network_name = azurerm_virtual_network.project-vnet.name # Link to parent VNet
  address_prefixes     = ["10.0.0.0/25"]                           # 128 IPs (lower half of /23)

  # Delegation required for PostgreSQL Flexible Server
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.DBforSQLServer/flexibleServers"               # Required service
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] # Allow VNet actions
    }
  }
}

# =================================================================================
# CREATE NETWORK SECURITY GROUP (NSG) FOR POSTGRESQL SUBNET
# =================================================================================
resource "azurerm_network_security_group" "sqlserver-nsg" {
  name                = "sqlserver-nsg"                         # NSG name
  location            = var.project_location                   # Region (from variable)
  resource_group_name = azurerm_resource_group.project_rg.name # Target RG

  # Allow inbound SQL Server traffic (default port 1433)
  security_rule {
    name                       = "Allow-SQLServer"
    priority                   = 1000      # Rule priority (lower = higher)
    direction                  = "Inbound" # Incoming traffic
    access                     = "Allow"   # Allow traffic
    protocol                   = "Tcp"     # TCP protocol
    source_port_range          = "*"       # All source ports
    destination_port_range     = "1433"    # SQL Server port
    source_address_prefix      = "*"       # All IPs
    destination_address_prefix = "*"       # All IPs
  }
}

# =================================================================================
# ASSOCIATE SQL SERVER SUBNET WITH ITS NSG
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "sqlserver-nsg-assoc" {
  subnet_id                 = azurerm_subnet.sqlserver-subnet.id              # Subnet reference
  network_security_group_id = azurerm_network_security_group.sqlserver-nsg.id # NSG reference
}

# =================================================================================
# DEFINE SUBNET FOR VIRTUAL MACHINES / APPLICATION WORKLOADS
# =================================================================================
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"                               # Subnet name (from variable)
  resource_group_name  = azurerm_resource_group.project_rg.name    # RG must match VNet's
  virtual_network_name = azurerm_virtual_network.project-vnet.name # Link to parent VNet
  address_prefixes     = ["10.0.1.0/25"]                           # 128 IPs (upper half of /23)
}

# =================================================================================
# CREATE NETWORK SECURITY GROUP (NSG) FOR VM SUBNET
# =================================================================================
resource "azurerm_network_security_group" "vm-nsg" {
  name                = "vm-nsg"                               # NSG name
  location            = var.project_location                   # Region (from variable)
  resource_group_name = azurerm_resource_group.project_rg.name # Target RG

  # Allow inbound HTTP traffic on port 80
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1000 # Rule priority
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow inbound SSH traffic on port 22
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001 # Lower priority than HTTP
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =================================================================================
# ASSOCIATE VM SUBNET WITH ITS NSG
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "vm-nsg-assoc" {
  subnet_id                 = azurerm_subnet.vm-subnet.id              # Subnet reference
  network_security_group_id = azurerm_network_security_group.vm-nsg.id # NSG reference
}
