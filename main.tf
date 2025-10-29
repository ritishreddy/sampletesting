terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.100.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

# ---------------------------
# Variables (edit these)
# ---------------------------
variable "resource_group_name" {
  description = "Existing Resource Group name"
  default     = "Test"
}

variable "location" {
  description = "Azure region"
  default     = "Australia Central"
}

variable "vnet_name" {
  description = "Existing Virtual Network name"
  default     = "vnet-australiacentral"
}

variable "subnet_name" {
  description = "Existing Subnet name"
  default     = "snet-australiacentral-1"
}

# ---------------------------
# Data sources (fetch existing resources)
# ---------------------------
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# ---------------------------
# Network Security Group (NSG)
# ---------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-tomcat"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                       = "Allow-Tomcat"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "8080"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# ---------------------------
# Public IP for each VM
# ---------------------------
resource "azurerm_public_ip" "public_ip" {
  count               = 2
  name                = "tomcat-publicip-${count.index + 1}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------------------------
# Network Interface (NIC)
# ---------------------------
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-tomcat-${count.index + 1}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-tomcat"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

# ---------------------------
# Associate NSG to NICs
# ---------------------------
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = 2
  network_interface_id       = azurerm_network_interface.nic[count.index].id
  network_security_group_id  = azurerm_network_security_group.nsg.id
}

# ---------------------------
# Linux Virtual Machines
# ---------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  count               = 2
  name                = "tomcat-vm-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "ritishreddy"
  admin_password      = "Ritishreddy@20021995"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  os_disk {
    name                 = "osdisk-tomcat-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    Name = "tomcatservers"
    Role = "Tomcat"
  }
}
