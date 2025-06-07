provider "azurerm" {
  features {}
  subscription_id = "cdeec537-7cf4-43eb-b9f0-635036cd1c66"
}

resource "azurerm_resource_group" "rg" {
  name     = "ubuntu-free-tier-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ubuntu-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "ubuntu-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_public_ip" "ip" {
  name                = "ubuntu-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "ubuntu-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }

}
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "ubuntu-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "ranjansir"
  admin_password      = "Ranjansir2025!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]



  disable_password_authentication = false

  os_disk {
    name                 = "ubuntu-os-disk"
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

resource "azurerm_virtual_machine_extension" "webserver" {
  name                 = "apache-webserver"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "commandToExecute": "sudo apt-get update && sudo apt-get install -y apache2 && sudo systemctl enable apache2 && sudo systemctl start apache2"
    }
SETTINGS
}


resource "azurerm_network_security_group" "nsg" {
  name                = "ubuntu-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
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
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the ubuntu-vm's network interface
resource "azurerm_network_interface_security_group_association" "nsg_association_ubuntu" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_storage_account" "storage" {
  name                     = "ubuntustorage${random_integer.rand_id.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_integer" "rand_id" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_container" "container" {
  name                  = "webcontent"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Resources for importing ansibleazurevm
resource "azurerm_resource_group" "rg_ansiblemachine" {
  name     = "ansiblemachine"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet_ansibleazurevm" {
  name                = "ansibleazurevm-vnet"
  address_space       = ["10.1.0.0/16"] # IMPORTANT: Verify actual address space in Azure
  location            = azurerm_resource_group.rg_ansiblemachine.location
  resource_group_name = azurerm_resource_group.rg_ansiblemachine.name
}

resource "azurerm_subnet" "subnet_ansibleazurevm_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg_ansiblemachine.name
  virtual_network_name = azurerm_virtual_network.vnet_ansibleazurevm.name
  address_prefixes     = ["10.1.0.0/24"] # IMPORTANT: Verify actual address prefixes in Azure
}

resource "azurerm_public_ip" "pip_ansibleazurevm" {
  name                = "ansibleazurevm-ip" # Matches the actual Public IP resource name in Azure
  location            = azurerm_resource_group.rg_ansiblemachine.location
  resource_group_name = azurerm_resource_group.rg_ansiblemachine.name
  allocation_method   = "Static" # IMPORTANT: Verify (Static or Dynamic)
  sku                 = "Basic"  # IMPORTANT: Verify (Basic or Standard)
  # The actual IP address 52.224.1.111 will be read from the imported state.
}

resource "azurerm_network_interface" "nic_ansibleazurevm" {
  name                = "ansibleazurevm-nic" # IMPORTANT: Verify actual Network Interface name in Azure
  location            = azurerm_resource_group.rg_ansiblemachine.location
  resource_group_name = azurerm_resource_group.rg_ansiblemachine.name

  ip_configuration {
    name                          = "ipconfig1" # IMPORTANT: Verify actual IP configuration name
    subnet_id                     = azurerm_subnet.subnet_ansibleazurevm_default.id
    private_ip_address_allocation = "Dynamic" # IMPORTANT: Verify (Dynamic or Static)
    public_ip_address_id          = azurerm_public_ip.pip_ansibleazurevm.id
  }
}

resource "azurerm_linux_virtual_machine" "vm_ansibleazurevm" {
  name                            = "ansibleazurevm"
  resource_group_name             = azurerm_resource_group.rg_ansiblemachine.name
  location                        = azurerm_resource_group.rg_ansiblemachine.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username # Uses variable from variables.tf
  admin_password                  = var.admin_password # Uses variable from variables.tf
  disable_password_authentication = false              # IMPORTANT: Set to true if using SSH key authentication

  network_interface_ids = [
    azurerm_network_interface.nic_ansibleazurevm.id,
  ]

  os_disk {
    name                 = "ansibleazurevm_disk1_83354e7776e149cf8e073c3a91a27631" # IMPORTANT: Verify actual OS Disk name in Azure
    caching              = "ReadWrite"                                             # IMPORTANT: Verify (e.g., ReadWrite, ReadOnly)
    storage_account_type = "Standard_LRS"                                          # IMPORTANT: Verify (e.g., Standard_LRS, Premium_LRS, StandardSSD_LRS)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # More specific offer for Ubuntu 22.04
    sku       = "22_04-lts"                    # Common SKU for Ubuntu 22.04 LTS (Gen1/Gen2 compatible)
    version   = "latest"
  }
}
