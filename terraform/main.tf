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

# Enabling shared key access prevention for an existing Azure Storage Account
resource "azurerm_storage_account" "stamarildo44637494179128" {
  name                     = "stamarildo44637494179128"
  resource_group_name      = "rg-amarildo-3329_ai"
  location                 = "North Europe" # Assuming the location as the default variable value
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  enable_shared_key_access  = false # Disabling shared key access for compliance
  is_hns_enabled           = false
  tags = {
    Environment = "production"
  }
}
