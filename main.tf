#############################
# Resource Group
#############################

resource "azurerm_resource_group" "rg" {
  name     = "rg-staging-neu"
  location = "northeurope"
}

#############################
# Log Analytics Workspace
#############################
# Required for the Container Apps environment.

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "law-staging-neu"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#############################
# Container Apps Environment
#############################

resource "azurerm_container_app_environment" "cae_staging" {
  name                       = "cae-staging-neu"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
}

#############################
# Container Registry (ACR)
#############################
# This registry can host your built container images. The admin is enabled here for simplicity.
# (In production you may want to disable admin and use a service principal.)

resource "azurerm_container_registry" "acrstaging" {
  name                = "acrstagingneu"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

#############################
# PostgreSQL Flexible Server
#############################
# This creates a managed PostgreSQL server and a single database.
# Adjust the version, SKU, and storage as needed.

resource "azurerm_postgresql_flexible_server" "staging" {
  name                   = "psql-staging-neu"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "13"
  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password
  zone                   = "2"

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
}

resource "azurerm_postgresql_flexible_server_database" "staging" {
  name      = "cloudgeni"
  server_id = azurerm_postgresql_flexible_server.staging.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

#############################
# Container App: Node API Service
#############################

# Create a single managed identity for all services
resource "azurerm_user_assigned_identity" "acr_access" {
  name                = "id-acr-access-staging"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Assign AcrPull and AcrPush roles to the identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acrstaging.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_access.principal_id
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acrstaging.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.acr_access.principal_id
}

#############################
# Container App: Python AI Service
#############################

# Create managed identities first
resource "azurerm_user_assigned_identity" "python_service" {
  name                = "id-python-service-staging"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_container_app" "python_service" {
  name                         = "ca-python-staging-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_staging.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode               = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access.id]
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access.id
  }

  ingress {
    external_enabled = true
    target_port     = 8000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "python-service"
      image  = "${azurerm_container_registry.acrstaging.login_server}/python-service:0b14bc96bdef25d303a76a6db1165d7626a2abd6"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8000"
      }
    }
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull
  ]
}

#############################
# Container App: Next.js Web App
#############################

# Create managed identities first
resource "azurerm_user_assigned_identity" "nextjs_app" {
  name                = "id-nextjs-app-staging"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_container_app" "nextjs_app" {
  name                         = "ca-nextjs-staging-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_staging.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode               = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access.id]
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access.id
  }

  ingress {
    external_enabled = true
    target_port     = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "web-app"
      image  = "${azurerm_container_registry.acrstaging.login_server}/web-app:0b14bc96bdef25d303a76a6db1165d7626a2abd6"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
    }
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull
  ]
}

#############################
# Container App: Node API Service
#############################

resource "azurerm_container_app" "node_api" {
  name                         = "ca-nodeapi-staging-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_staging.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode               = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access.id]
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access.id
  }

  ingress {
    external_enabled = true
    target_port     = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "node-server"
      image  = "${azurerm_container_registry.acrstaging.login_server}/node-server:0b14bc96bdef25d303a76a6db1165d7626a2abd6"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
    }
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull
  ]
}

#############################
# Key Vault
#############################
# Reference to existing Key Vault

resource "azurerm_key_vault" "staging" {
  name                        = "kv-amarildo637494179128"
  location                    = "swedencentral"
  resource_group_name         = "rg-amarildo-3329_ai"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  enable_rbac_authorization   = false

  network_acls {
    default_action             = "Deny"              # Deny all traffic by default
    bypass                     = "AzureServices"     # Allow trusted Azure services
    ip_rules                   = []                  # Add your IP address here
    virtual_network_subnet_ids = []
  }

  access_policy {
    tenant_id = "597bfa71-7575-4506-93d7-dc147bddfb22"
    object_id = "4f2647b3-fb4e-4037-b496-db12c65ed1ff"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers",
      "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey",
      "Verify", "Sign", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    storage_permissions = []
  }

  access_policy {
    tenant_id = "597bfa71-7575-4506-93d7-dc147bddfb22"
    object_id = "9e14b50a-b39e-4a79-b934-b99e67915933"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers",
      "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey",
      "Verify", "Sign", "Release", "Rotate", "GetRotationPolicy",
      "SetRotationPolicy"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
    storage_permissions = []
  }

  access_policy {
    tenant_id = "597bfa71-7575-4506-93d7-dc147bddfb22"
    object_id = "2546a174-cc9e-43cb-bf83-53070916889e"

    certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
    key_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    storage_permissions = []
  }

  access_policy {
    tenant_id = "597bfa71-7575-4506-93d7-dc147bddfb22"
    object_id = "b72f6fe4-2ad4-4dcd-90f9-b1972729704a"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers",
      "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
      "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey",
      "Verify", "Sign", "Release", "Rotate", "GetRotationPolicy",
      "SetRotationPolicy"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
    storage_permissions = []
  }
}

# Add this to get current Azure context
data "azurerm_client_config" "current" {}
