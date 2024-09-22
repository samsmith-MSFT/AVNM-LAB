terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "spoke_vnets" {
  for_each = toset(var.vnet_name_spokes)
  name                = each.value
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "spoke_subnets" {
  for_each = toset(var.vnet_name_spokes)
  name                 = "${each.key}-subnet"
  virtual_network_name = data.azurerm_virtual_network.spoke_vnets[each.key].name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nics" {
  for_each = data.azurerm_subnet.spoke_subnets
  name                = "${each.key}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = data.azurerm_subnet.spoke_subnets
  name                = "${each.key}-vm"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B2ls_v2"
  disable_password_authentication = false
  admin_username      = "azureadmin"
  admin_password      = "AzureAdmin123!"
  network_interface_ids = [azurerm_network_interface.nics[each.key].id]
  boot_diagnostics {
    storage_account_uri = null
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}