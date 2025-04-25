terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.70.0"
    }
  }
}

provider "azurerm" {
  features {}
	skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "${var.app_service_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"
}

# Windows Web App with Authentication Settings
resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    # Add necessary site configuration here, e.g., .NET Framework version
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "CLIENT_SECRET"            = var.client_secret
  }
}

# Azure SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "adminuser"
  administrator_login_password = var.sql_admin_password
}

# Azure SQL Database
resource "azurerm_mssql_database" "sqldb" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

# Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "${var.app_service_name}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Virtual Network (placeholder if networking does not exist already)
resource "azurerm_virtual_network" "vm_vnet" {
  name                = "${var.vm_name}-vnet"
  location            = var.vm_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet (inside Virtual Network)
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.vm_location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "${var.vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.vm_location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  admin_username = "azureuser"
  admin_password = var.sql_admin_password
}
