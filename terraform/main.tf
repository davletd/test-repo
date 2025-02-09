
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

      # Virtual Network
      resource "azurerm_virtual_network" "vnet" {
        name                = "vm-vnet"
        location            = "westeurope"
        resource_group_name = azurerm_resource_group.rg.name
        address_space       = ["10.0.0.0/16"]
      }

      # Subnet
      resource "azurerm_subnet" "subnet" {
        name                 = "vm-subnet"
        resource_group_name  = azurerm_resource_group.rg.name
        virtual_network_name = azurerm_virtual_network.vnet.name
        address_prefixes     = ["10.0.1.0/24"]
      }

      # Public IP
      resource "azurerm_public_ip" "pip" {
        name                = "vm-public-ip"
        location            = "westeurope"
        resource_group_name = azurerm_resource_group.rg.name
        allocation_method   = "Dynamic"
      }

      # Network Interface
      resource "azurerm_network_interface" "nic" {
        name                = "vm-nic"
        location            = "westeurope"
        resource_group_name = azurerm_resource_group.rg.name

        ip_configuration {
          name                          = "vm-ipconfig"
          subnet_id                     = azurerm_subnet.subnet.id
          private_ip_address_allocation = "Dynamic"
          public_ip_address_id          = azurerm_public_ip.pip.id
        }
      }

      # Virtual Machine
      resource "azurerm_windows_virtual_machine" "vm" {
        name                = "vm-eu"
        location            = "westeurope"
        resource_group_name = azurerm_resource_group.rg.name
        size                = "Standard_D2s_v3"
        admin_username      = "adminuser"
        admin_password      = var.vm_admin_password

        network_interface_ids = [
          azurerm_network_interface.nic.id
        ]

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
      }