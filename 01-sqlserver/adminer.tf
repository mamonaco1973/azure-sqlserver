# ================================================================================
# NETWORK INTERFACE: ADMINER VM
# ================================================================================
# Creates a network interface for the Adminer virtual machine.
#
# The NIC is attached to the VM subnet and associated with a static
# public IP to allow inbound access to the Adminer web interface.
# ================================================================================
resource "azurerm_network_interface" "adminer-vm-nic" {
  name                = "adminer-vm-nic"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adminer_vm_public_ip.id
  }
}


# ================================================================================
# LINUX VIRTUAL MACHINE: ADMINER
# ================================================================================
# Provisions a lightweight Ubuntu Linux virtual machine used to host
# the Adminer web UI for database administration and testing.
#
# Notes:
#   - Password authentication is enabled for simplicity.
#   - Cloud-init installs and configures Adminer at boot.
#   - VM creation depends on SQL Server resources.
# ================================================================================
resource "azurerm_linux_virtual_machine" "adminer-vm" {
  name                = "adminer-vm"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  size           = "Standard_B1s"
  admin_username = "sysadmin"
  admin_password = random_password.vm_password.result

  disable_password_authentication = false

  # ------------------------------------------------------------------------------
  # NETWORK INTERFACES
  # ------------------------------------------------------------------------------
  network_interface_ids = [
    azurerm_network_interface.adminer-vm-nic.id
  ]

  # ------------------------------------------------------------------------------
  # OPERATING SYSTEM DISK
  # ------------------------------------------------------------------------------
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # ------------------------------------------------------------------------------
  # SOURCE IMAGE: UBUNTU 24.04 LTS
  # ------------------------------------------------------------------------------
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # ------------------------------------------------------------------------------
  # CLOUD-INIT CONFIGURATION
  # ------------------------------------------------------------------------------
  custom_data = base64encode(templatefile(
    "./scripts/adminer.sh.template",
    {
      DBPASSWORD    = random_password.sqlserver_password.result
      DBUSER        = "sqladmin"
      DBENDPOINT    = "sqlserver-${random_string.suffix.result}.database.windows.net"
      DBENDPOINT_MI = azurerm_mssql_managed_instance.sql_mi.fqdn
    }
  ))

  depends_on = [
    azurerm_mssql_server.sql_server_instance,
    azurerm_mssql_managed_instance.sql_mi
  ]
}


# ================================================================================
# PUBLIC IP: ADMINER VM
# ================================================================================
# Creates a static public IP address for the Adminer VM.
#
# The Standard SKU is required for production workloads and provides
# improved availability and security over the Basic SKU.
# ================================================================================
resource "azurerm_public_ip" "adminer_vm_public_ip" {
  name                = "adminer-vm-public-ip"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  allocation_method = "Static"
  sku               = "Standard"

  domain_name_label = "adminer-${random_string.suffix.result}"
}
