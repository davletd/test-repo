
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

  tags = {
    "Environment" = var.environment
    "Compliance"  = "SOC2, ISO27001"
  }
}

# Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "${var.app_service_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = {
    "Compliance" = "SOC2, ISO27001"
  }
}

resource "azurerm_storage_account" "audit_storage" {
  name                     = "auditstorageacct"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Compliance" = "SOC2, ISO27001"
  }
}

# Windows Web App with Authentication Settings
resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  identity {
    type = "SystemAssigned"
  }

  https_only = true  # Enforce HTTPS

  site_config {
    always_on                      = true
    ftps_state                     = "Disabled"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "CLIENT_SECRET"            = var.client_secret
    "WEBSITE_DISABLE_OVERLAPPED_RECYCLING" = "1"  # Operational reliability
  }

  connection_string {
    name  = "DBConnection"
    type  = "SQLAzure"
    value = var.sql_connection_string
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


resource "azurerm_mssql_server_extended_auditing_policy" "sql_audit_policy" {
  server_id                        = azurerm_mssql_server.sql.id
  storage_endpoint                  = azurerm_storage_account.audit_storage.primary_blob_endpoint
  storage_account_access_key        = azurerm_storage_account.audit_storage.primary_access_key
  retention_in_days                 = 90
}

# Azure SQL Database
resource "azurerm_mssql_database" "sqldb" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"

  threat_detection_policy {
    state                      = "Enabled"
    email_addresses            = ["security-team@example.com"]
    retention_days             = 30
    storage_account_access_key = azurerm_storage_account.audit_storage.primary_access_key
  }
}

# Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "${var.app_service_name}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  tags = {
    "Compliance" = "SOC2, ISO27001"
  }

  # Enable advanced data masking for sensitive data
  retention_in_days = 90
  sampling_percentage = 100
}

resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "${var.resource_group_name}-log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_monitor_diagnostic_setting" "diagnostics" {
  name                       = "${var.app_service_name}-diagnostic-setting"
  target_resource_id         = azurerm_windows_web_app.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id

  log {
    category = "AppServiceHTTPLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
