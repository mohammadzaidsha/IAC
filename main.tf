provider "azurerm" {
  features {}
  subscription_id = "4e814c9d-353a-409b-ad61-28ef8ad9baf3"
}

# Create a Resource Group
resource "azurerm_resource_group" "boston" {
  name     = "boston-rg"
  location = "East US"
}

# Create a Virtual Network
resource "azurerm_virtual_network" "boston" {
  name                = "boston-vnet"
  location            = azurerm_resource_group.boston.location
  resource_group_name = azurerm_resource_group.boston.name
  address_space       = ["10.0.0.0/16"]
}

# Create a Subnet
resource "azurerm_subnet" "boston" {
  name                 = "boston-subnet"
  resource_group_name  = azurerm_resource_group.boston.name
  virtual_network_name = azurerm_virtual_network.boston.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Network Interfaces (One for each VM)
resource "azurerm_network_interface" "boston" {
  count               = 5
  name                = "bostonni-${count.index}"
  location            = azurerm_resource_group.boston.location
  resource_group_name = azurerm_resource_group.boston.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.boston.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create 5 Virtual Machines without Public IP
resource "azurerm_linux_virtual_machine" "boston" {
  count               = 5
  name                = "bostonvms${count.index}"
  resource_group_name = azurerm_resource_group.boston.name
  location            = azurerm_resource_group.boston.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.boston[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Create Auto-Shutdown for Each VM at 7:30 PM IST
resource "azurerm_dev_test_global_vm_shutdown_schedule" "boston" {
  count               = 5
  virtual_machine_id  = azurerm_linux_virtual_machine.boston[count.index].id
  location            = azurerm_resource_group.boston.location
  enabled             = true
  daily_recurrence_time = "1400"  # 14:00 UTC = 7:30 PM IST
  timezone           = "India Standard Time"

  notification_settings {
    enabled = false
  }
}
