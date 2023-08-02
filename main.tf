
# Resource group
resource "azurerm_resource_group" "WeightTracker_rg" {
  name     = "${var.resource_group_name}${var.project_name}"
  location = "West Europe"
}

# Virtual network
resource "azruerm_virtual_network" "WeightTracker_vnet" {
    name                = "${var.virtual_network_name}${var.project_name}"
    resource_group_name = azurerm_resource_group.WeightTracker_rg.name
    location            = azurerm_resource_group.WeightTracker_rg.location
    address_space       = ["10.0.0.0/16"]
}

# Subnet for web host
resource "azurerm_subnet" "web_subnet"{
    virtual_network_name = azurerm_virtual_netwrok.WeightTracker_vnet.name
    name                 = "${var.subnet_name}-web"
    resource_group_name  = azurerm_resource_group.WeightTracker_rg.name
    address_prefixes     = "${var.web_subnet_mask}"
}

# Subnet for PostgresSQL DB
resource "azurerm_subnet" "db_subnet"{
    virtual_network_name = azurerm_virtual_netwrok.WeightTracker_vnet.name
    name                 = "${var.subnet_name}-db"
    resource_group_name  = azurerm_resource_group.WeightTracker_rg.name
    address_prefixes     = "${var.db_subnet_mask}"
}

# NSG open to the web
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.network_security_group_name}-Web"
  location            = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  # Adding the security rules
  security_rule {
      name                       = "Allow-SSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    security_rule {
      name                       = "Allow-8080"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    security_rule {
      name                       = "Allow-HTTP"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }


# Web NSG association
resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# NSG close to the web for the db
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.network_security_group_name}-db"
  location            = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  # Adding the security rules
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "Allow-psql"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }
}

# DB NSG association
resource "azurerm_subnet_network_security_group_association" "db_nsg_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

resource "azurerm_public_ip" "web_public_ip" {
  name = "web-public-ip"
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  location = azurerm_resource_group.WeightTracker_rg.location
  allocation_method = "Static"
}

resource "azurerm_network_interface" "web_nic" {
  name = "web_nic"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  ip_configuration {
    name = "web_nic-test"
    subnet_id = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.web_public_ip.id
  }
}

resource "azurerm_network_interface" "db_nic" {
  name = "db-nic"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  ip_configuration {
    name = "db-nic-test"
    subnet_id = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "web_vm" {
  name = "${var.vm_name}${var.project_name}-web"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  network_interface_ids = [ azurerm_network_interface.web_nic.id ]
  vm_size = "Standard_DS1_v2"
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "webdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vm_name}${var.project_name}-web"
    admin_username = "sshuser"
    admin_password = "data.azurerm_key_vault_secret.sshPass"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  connection {
    type     = "ssh"
    user     = "sshuser"
    password = "data.azurerm_key_vault_secret.sshPass"
    host     = azurerm_public_ip.web_public_ip.ip_address
    timeout = "40s"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install postgresql-client -y",
      "sudo apt install net-tools -y",
      "sudo apt install python3-virtualenv -y",
      "sudo apt install python3-pip -y",
      "sudo apt install virtualenv",
      "sudo apt-get -y install libpq-dev gcc",
      "git clone https://github.com/itsvictorfy/flaskapp.git",
      "cd flaskapp",
      "virtualenv flask",
      "cd flask",
      "source bin/activate",
      "pip3 install psycopg2",
      "pip3 install Flask",
      "python3 ../app.py &"
     ]
    
  }
}

resource "azurerm_storage_account" "sa_db" {
  name = "testweighttracker"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_managed_disk" "db_volume" {
  name= "db-volume"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = 4
  storage_account_id = azurerm_storage_account.sa_db.id
}

resource "azurerm_virtual_machine" "db_vm" {
  name = "${var.vm_name}${var.project_name}-db"
  location = azurerm_resource_group.WeightTracker_rg.location
  resource_group_name = azurerm_resource_group.WeightTracker_rg.name
  network_interface_ids = [azurerm_network_interface.db-nic.id]
  vm_size = "Standard_DS1_v2"
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "dbdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vm_name}${var.project_name}-db"
    admin_username = "sshuser"
    admin_password = "data.azurerm_key_vault_secret.sshPass"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  connection {
    type     = "ssh"
    user     = "sshuser"
    password = "data.azurerm_key_vault_secret.sshPass"
    host = azurerm_network_interface.db-nic.private_ip_address
    timeout = "40s"
  }
  provisioner "remote-exec" {
    inline = [
      "git clone git@gitlab.com:sela-1090/students/itsvictorfy/terraform.git",
      "cd terraform",
      "sudo bash psqlSerInstall.sh"
     ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "db_volume_attachment" {
  managed_disk_id = azurerm_managed_disk.db_volume.id
  virtual_machine_id = azurerm_virtual_machine.db_vm.id
  lun = 0
  caching = "None"
}