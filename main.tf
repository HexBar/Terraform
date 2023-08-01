# Resource group
resource "azurerm_resource_group" "terraform_final_project_rg" {
  name     = "${var.resource_group_name}${var.project_name}"
  location = "West Europe"
}

# Virtual network
resource "azruerm_virtual_network" "terraform_first_project_vnet" {
    name                = "${var.virtual_network_name}${var.project_name}"
    resource_group_name = azurerm_resource_group.terraform_first_project_rg.name
    location            = azurerm_resource_group.terraform_first_project_rg.location
    address_space       = ["10.0.0.0/16"]
}

# Subnet for web host
resource "azurerm_subnet" "web_subnet"{
    virtual_network_name = azurerm_virtual_netwrok.terraform_first_project_vnet.name
    name                 = "${var.subnet_name}-web"
    resource_group_name  = azurerm_resource_group.terraform_first_project_rg.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for PostgresSQL DB
resource "azurerm_subnet" "db_subnet"{
    virtual_network_name = azurerm_virtual_netwrok.terraform_first_project_vnet.name
    name                 = "${var.subnet_name}-db"
    resource_group_name  = azurerm_resource_group.terraform_first_project_rg.name
    address_prefixes     = ["10.0.2.0/24"]
}

# NSG open to the web
resource "azurerm_network_security_group" "open_to_web_security_group" {
  name                = "${var.network_security_group_name}-OpenToWeb"
  location            = azurerm_resource_group.terraform_first_project_rg.location
  resource_group_name = azurerm_resource_group.terraform_first_project_rg.name
}

# Creating the NSG rules
resource "azurerm_network_security_rule" "webrules" {
  for_each                    = local.nsgrulesweb 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.terraform_first_project_rg.name
  network_security_group_name = azurerm_network_security_group.open_to_web_security_group.name
}

# Web NSG association
resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.open_to_web_security_group.id
}

# NSG close to the web for the db
resource "azurerm_network_security_group" "close_to_web_security_group" {
  name                = "${var.network_security_group_name}-CloseToWeb"
  location            = azurerm_resource_group.terraform_first_project_rg.location
  resource_group_name = azurerm_resource_group.terraform_first_project_rg.name
}

# Creating the NSG rules
resource "azurerm_network_security_rule" "dbrules" {
  for_each                    = local.nsgrulesdb 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.terraform_first_project_rg.name
  network_security_group_name = azurerm_network_security_group.close_to_web_security_group.name
}

# DB NSG association
resource "azurerm_subnet_network_security_group_association" "db_nsg_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.close_to_web_security_group.id
}
