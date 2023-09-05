#This block is for creating public key to SSH Azure Linux VM
resource "tls_private_key" "tf-ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#This block is for creating resource group
resource "azurerm_resource_group" "tf-rg" {
  name     = "tf-rg"
  location = "West Europe"
}

#This block is for creating Virtual Network
resource "azurerm_virtual_network" "tf-vnet" {
  name                = "tf-vnet"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Demo"
  }
}

#This block is for creating a subnet
resource "azurerm_subnet" "tf-subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.tf-rg.name
  virtual_network_name = azurerm_virtual_network.tf-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

#This block is for creating Network Security Group
resource "azurerm_network_security_group" "tf-nsg" {
  name                = "tf-nsg"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name

  security_rule {
    name                       = "tf-nsg-Inbound-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Demo"
  }
}

#This block is for associating subnet with Network Security Group
resource "azurerm_subnet_network_security_group_association" "tf-subnet-associate" {
  subnet_id                 = azurerm_subnet.tf-subnet.id
  network_security_group_id = azurerm_network_security_group.tf-nsg.id

}

#This block is for creating Public IP address
resource "azurerm_public_ip" "tf-pip" {
  name                = "tf-pip"
  resource_group_name = azurerm_resource_group.tf-rg.name
  location            = azurerm_resource_group.tf-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Demo"
  }
}

#This block is for creating Network Interface Card
resource "azurerm_network_interface" "tf-nic" {
  name                = "tf-nic"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-pip.id
  }
}

#This block is for creating VM
resource "azurerm_linux_virtual_machine" "tf-linuxvm" {
  name                = "tf-linuxvm"
  resource_group_name = azurerm_resource_group.tf-rg.name
  location            = azurerm_resource_group.tf-rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.tf-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.tf-ssh.public_key_openssh # here we made to resource tls_private_key.tf-ssh to create public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
} 