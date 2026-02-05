# ================================================================================
# VIRTUAL NETWORK: PROJECT VNET
# ================================================================================
# Creates the primary VNet that hosts all subnets for this deployment.
#
# CIDR PLAN:
#   - VNet:        10.0.0.0/23
#   - SQL subnet:  10.0.0.0/25
#   - VM subnet:   10.0.0.128/25
#   - MI subnet:   10.0.1.0/24
# ================================================================================
resource "azurerm_virtual_network" "project-vnet" {
  name                = var.project_vnet                       # VNet name (input)
  address_space       = ["10.0.0.0/23"]                        # /23 = 512 IPs
  location            = var.project_location                   # Azure region
  resource_group_name = azurerm_resource_group.project_rg.name # Target RG
}

# ================================================================================
# SUBNET: SQL SERVER
# ================================================================================
# Subnet used for SQL Server-related resources (non-Managed Instance).
# ================================================================================
resource "azurerm_subnet" "sqlserver-subnet" {
  name                 = var.project_subnet                        # Subnet name
  resource_group_name  = azurerm_resource_group.project_rg.name    # Same RG
  virtual_network_name = azurerm_virtual_network.project-vnet.name # Parent VNet
  address_prefixes     = ["10.0.0.0/25"]                           # /25 = 128 IPs
}

# ================================================================================
# NSG: SQL SERVER SUBNET
# ================================================================================
# Network Security Group applied to the SQL Server subnet.
#
# NOTE:
#   This rule is permissive ("*"). Prefer restricting to VM subnet CIDR
#   or specific admin IPs for tighter security.
# ================================================================================
resource "azurerm_network_security_group" "sqlserver-nsg" {
  name                = "sqlserver-nsg"                        # NSG name
  location            = var.project_location                   # Azure region
  resource_group_name = azurerm_resource_group.project_rg.name # Target RG

  security_rule {
    name                       = "Allow-SQLServer"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ================================================================================
# NSG ASSOCIATION: SQL SERVER SUBNET
# ================================================================================
# Binds the SQL Server subnet to its NSG.
# ================================================================================
resource "azurerm_subnet_network_security_group_association" "sqlserver-nsg-assoc" {
  subnet_id                 = azurerm_subnet.sqlserver-subnet.id
  network_security_group_id = azurerm_network_security_group.sqlserver-nsg.id
}

# ================================================================================
# SUBNET: VIRTUAL MACHINES / APP WORKLOADS
# ================================================================================
# Subnet used for Adminer / helper VMs and related app workloads.
# ================================================================================
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"                               # Subnet name
  resource_group_name  = azurerm_resource_group.project_rg.name    # Same RG
  virtual_network_name = azurerm_virtual_network.project-vnet.name # Parent VNet
  address_prefixes     = ["10.0.0.128/25"]                         # /25 = 128 IPs
}

# ================================================================================
# NSG: VM SUBNET
# ================================================================================
# Network Security Group applied to the VM subnet.
#
# NOTE:
#   These rules are permissive ("*"). Prefer limiting:
#     - SSH (22) to your public IP
#     - HTTP (80) to only what you need
# ================================================================================
resource "azurerm_network_security_group" "vm-nsg" {
  name                = "vm-nsg"                               # NSG name
  location            = var.project_location                   # Azure region
  resource_group_name = azurerm_resource_group.project_rg.name # Target RG

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ================================================================================
# NSG ASSOCIATION: VM SUBNET
# ================================================================================
# Binds the VM subnet to its NSG.
# ================================================================================
resource "azurerm_subnet_network_security_group_association" "vm-nsg-assoc" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}

# ================================================================================
# SUBNET: SQL MANAGED INSTANCE
# ================================================================================
# Dedicated subnet for SQL Managed Instance (MI).
#
# REQUIREMENTS:
#   - Must be a dedicated subnet (no other resources).
#   - Must be delegated to Microsoft.Sql/managedInstances.
#   - Size requirements vary; /24 is commonly used.
# ================================================================================
resource "azurerm_subnet" "sql_mi_subnet" {
  name                 = "sql-mi-subnet"
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "managedinstancedelegation"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ================================================================================
# NSG: SQL MANAGED INSTANCE SUBNET
# ================================================================================
# Network Security Group applied to the SQL MI subnet.
#
# NOTE:
#   SQL MI has specific network requirements. Keep rules aligned with
#   Microsoft guidance for your chosen connectivity model.
# ================================================================================
resource "azurerm_network_security_group" "sql_mi_nsg" {
  name                = "sql-mi-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "Allow-SQLMI"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Azure-LB"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ================================================================================
# NSG ASSOCIATION: SQL MANAGED INSTANCE SUBNET
# ================================================================================
# Binds the SQL MI subnet to its NSG.
# ================================================================================
resource "azurerm_subnet_network_security_group_association" "sqlserver-mi-nsg-assoc" {
  subnet_id                 = azurerm_subnet.sql_mi_subnet.id
  network_security_group_id = azurerm_network_security_group.sql_mi_nsg.id
}

# ================================================================================
# ROUTE TABLE: SQL MANAGED INSTANCE SUBNET
# ================================================================================
# Creates a route table to associate with the SQL MI subnet.
#
# NOTE:
#   SQL MI commonly requires a route table association even if no custom
#   routes are defined initially.
# ================================================================================
resource "azurerm_route_table" "sql_mi_rt" {
  name                = "sql-mi-route-table"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
}

# ================================================================================
# ROUTE TABLE ASSOCIATION: SQL MANAGED INSTANCE SUBNET
# ================================================================================
# Binds the route table to the SQL MI subnet.
# ================================================================================
resource "azurerm_subnet_route_table_association" "sql_mi_rt_assoc" {
  subnet_id      = azurerm_subnet.sql_mi_subnet.id
  route_table_id = azurerm_route_table.sql_mi_rt.id
}
