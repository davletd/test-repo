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

# Enable pg_vector extension
resource "azurerm_postgresql_flexible_server_configuration" "vector_extension" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.staging.id
  value     = "vector"
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
  max_inactive_revisions      = 100

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
      image  = "${azurerm_container_registry.acrstaging.login_server}/python-service:${var.python_service_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8000"
      }
      
      env {
        name  = "DB_HOST"
        value = "psql-staging-neu.postgres.database.azure.com"
      }
      
      env {
        name  = "DB_USER"
        value = "myadmin"
      }
      
      env {
        name  = "DB_PASSWORD"
        value = "P@ssw0rd123!"
      }
      
      env {
        name  = "DB_NAME"
        value = "cloudgeni"
      }
      
      env {
        name  = "API_KEY_OPENAI"
        value = "AIsNrbqueYjMQyKNa5YE2z4MG6PF2GVHn1U2IDZ6la5j2Ul7dTJJJQQJ99BAACfhMk5XJ3w3AAAAACOGzIFo"
      }
      
      env {
        name  = "BASE_URL_OPENAI"
        value = "https://ai-amarildo4437ai637494179128.openai.azure.com/"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://myadmin:Cloudgeni-2025!@psql-staging-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "LANGFUSE_PUBLIC_KEY"
        value = ""
      }
      
      env {
        name  = "LANGFUSE_SECRET_KEY"
        value = ""
      }
      
      env {
        name  = "LANGFUSE_HOST"
        value = "https://langfuse.staging.cloudgeni.ai:8001"
      }
      
      env {
        name  = "MODEL"
        value = "gpt-4o"
      }
      
      env {
        name  = "MAX_ITERATIONS"
        value = "2"
      }
      
      env {
        name  = "SUPERVISOR_MODEL"
        value = ""
      }
      
      env {
        name  = "WORKER_MODEL"
        value = ""
      }
      
      env {
        name  = "MAX_SUPERVISOR_ITERATIONS"
        value = ""
      }
      
      env {
        name  = "MAX_WORKER_ITERATIONS"
        value = ""
      }
      
      env {
        name  = "TMP_BASE_PATH"
        value = "/tmp/cloudgeni"
      }
      
      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = "https://ai-amarildo4437ai637494179128.openai.azure.com/"
      }
      
      env {
        name  = "AZURE_OPENAI_DEPLOYMENT"
        value = "gpt-4o"
      }
      
      env {
        name  = "AZURE_API_KEY"
        value = ""
      }
      
      env {
        name  = "AZURE_API_BASE"
        value = ""
      }
      
      env {
        name  = "AZURE_API_VERSION"
        value = ""
      }
      
      env {
        name  = "GEMINI_API_KEY"
        value = ""
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
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
  max_inactive_revisions      = 100

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
      image  = "${azurerm_container_registry.acrstaging.login_server}/web-app:${var.nextjs_app_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      
      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://api.staging.cloudgeni.ai"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://myadmin:Cloudgeni-2025!@psql-staging-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "NEXT_PUBLIC_URL"
        value = "https://staging.cloudgeni.ai"
      }
      
      env {
        name  = "NEXT_PUBLIC_COOKIE_DOMAIN"
        value = "staging.cloudgeni.ai"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
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
  max_inactive_revisions      = 100

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
    target_port     = 3001
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1
    
    container {
      name   = "node-server"
      image  = "${azurerm_container_registry.acrstaging.login_server}/node-server:${var.node_api_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      
      env {
        name  = "NODE_ENV"
        value = "cae-staging-neu"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@psql-staging-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "GITHUB_TOKEN"
        value = var.github_token
      }
      
      env {
        name  = "GITHUB_APP_ID"
        value = var.github_app_id
      }
      
      env {
        name  = "GITHUB_PRIVATE_KEY"
        value = var.github_private_key
      }
      
      env {
        name  = "API_KEY_OPENAI"
        value = var.openai_api_key
      }
      
      env {
        name  = "GOOGLE_CLIENT_ID"
        value = var.google_client_id
      }
      
      env {
        name  = "GOOGLE_CLIENT_SECRET"
        value = var.google_client_secret
      }
      
      env {
        name  = "GOOGLE_OAUTH_CALLBACK_URL"
        value = "https://api.staging.cloudgeni.ai/auth/google/callback"
      }
      
      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://api.staging.cloudgeni.ai"
      }
      
      env {
        name  = "NEXT_PUBLIC_URL"
        value = "https://staging.cloudgeni.ai"
      }
      
      env {
        name  = "GITHUB_APP_NAME"
        value = var.github_app_name
      }
      
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull
  ]
}

#############################
# Container App: Langfuse
#############################

resource "azurerm_container_app" "langfuse" {
  name                         = "ca-langfuse-staging-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_staging.id
  resource_group_name         = azurerm_resource_group.rg.name
  revision_mode               = "Single"

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
      name   = "langfuse"
      image  = var.langfuse_image
      cpu    = 1
      memory = "2Gi"

      env {
        name  = "PORT"
        value = "3000"
      }

      # Langfuse required environment variables
      env {
        name  = "NEXTAUTH_SECRET"
        value = var.nextauth_secret
      }

      env {
        name  = "POSTGRES_PRISMA_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.staging.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "POSTGRES_URL_NON_POOLING"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.staging.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.staging.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "NEXTAUTH_URL"
        value = "https://ca-langfuse-staging-neu.${azurerm_container_app_environment.cae_staging.default_domain}"
      }

      env {
        name  = "SALT"
        value = var.langfuse_salt
      }

      env {
        name  = "TELEMETRY_ENABLED"
        value = "false"
      }

      env {
        name  = "CORS_ORIGIN"
        value = "*"
      }

      env {
        name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
        value = "true"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull,
    azurerm_postgresql_flexible_server.staging
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

#############################
# Beta Environment Resources
#############################

resource "azurerm_resource_group" "rg_beta" {
  name     = "rg-beta-neu"
  location = "northeurope"
}

# Create a managed identity for ACR access in beta environment
resource "azurerm_user_assigned_identity" "acr_access_beta" {
  name                = "id-acr-access-beta"
  resource_group_name = azurerm_resource_group.rg_beta.name
  location            = azurerm_resource_group.rg_beta.location
}

# Assign AcrPull and AcrPush roles to the beta identity
resource "azurerm_role_assignment" "acr_pull_beta" {
  scope                = azurerm_container_registry.acrstaging.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_access_beta.principal_id
}

resource "azurerm_role_assignment" "acr_push_beta" {
  scope                = azurerm_container_registry.acrstaging.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.acr_access_beta.principal_id
}

#############################
# Log Analytics Workspace - Beta
#############################

resource "azurerm_log_analytics_workspace" "log_analytics_beta" {
  name                = "law-beta-neu"
  location            = azurerm_resource_group.rg_beta.location
  resource_group_name = azurerm_resource_group.rg_beta.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#############################
# Container Apps Environment - Beta
#############################

resource "azurerm_container_app_environment" "cae_beta" {
  name                       = "cae-beta-neu"
  location                   = azurerm_resource_group.rg_beta.location
  resource_group_name        = azurerm_resource_group.rg_beta.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_beta.id
}

#############################
# PostgreSQL Flexible Server - Beta
#############################

resource "azurerm_postgresql_flexible_server" "beta" {
  name                   = "psql-beta-neu"
  resource_group_name    = azurerm_resource_group.rg_beta.name
  location               = azurerm_resource_group.rg_beta.location
  version                = "13"
  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password
  zone                   = "2"

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
}

resource "azurerm_postgresql_flexible_server_database" "beta" {
  name      = "cloudgeni"
  server_id = azurerm_postgresql_flexible_server.beta.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Enable pg_vector extension for beta
resource "azurerm_postgresql_flexible_server_configuration" "vector_extension_beta" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.beta.id
  value     = "vector"
}

#############################
# Container App: Python AI Service - Beta
#############################

# Create managed identity for beta
resource "azurerm_user_assigned_identity" "python_service_beta" {
  name                = "id-python-service-beta"
  resource_group_name = azurerm_resource_group.rg_beta.name
  location            = azurerm_resource_group.rg_beta.location
}

resource "azurerm_container_app" "python_service_beta" {
  name                         = "ca-python-beta-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_beta.id
  resource_group_name          = azurerm_resource_group.rg_beta.name
  revision_mode               = "Single"
  max_inactive_revisions      = 100

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access_beta.id]  # Using beta environment ACR access identity
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access_beta.id
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
      image  = "${azurerm_container_registry.acrstaging.login_server}/python-service:${var.python_service_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8000"
      }
      
      env {
        name  = "DB_HOST"
        value = "psql-beta-neu.postgres.database.azure.com"
      }
      
      env {
        name  = "DB_USER"
        value = "myadmin"
      }
      
      env {
        name  = "DB_PASSWORD"
        value = "P@ssw0rd123!"
      }
      
      env {
        name  = "DB_NAME"
        value = "cloudgeni"
      }
      
      env {
        name  = "API_KEY_OPENAI"
        value = "AIsNrbqueYjMQyKNa5YE2z4MG6PF2GVHn1U2IDZ6la5j2Ul7dTJJJQQJ99BAACfhMk5XJ3w3AAAAACOGzIFo"
      }
      
      env {
        name  = "BASE_URL_OPENAI"
        value = "https://ai-amarildo4437ai637494179128.openai.azure.com/"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://myadmin:Cloudgeni-2025!@psql-beta-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "LANGFUSE_PUBLIC_KEY"
        value = ""
      }
      
      env {
        name  = "LANGFUSE_SECRET_KEY"
        value = ""
      }
      
      env {
        name  = "LANGFUSE_HOST"
        value = "https://langfuse.beta.cloudgeni.ai:8001"
      }
      
      env {
        name  = "MODEL"
        value = "gpt-4o"
      }
      
      env {
        name  = "MAX_ITERATIONS"
        value = "2"
      }
      
      env {
        name  = "SUPERVISOR_MODEL"
        value = ""
      }
      
      env {
        name  = "WORKER_MODEL"
        value = ""
      }
      
      env {
        name  = "MAX_SUPERVISOR_ITERATIONS"
        value = ""
      }
      
      env {
        name  = "MAX_WORKER_ITERATIONS"
        value = ""
      }
      
      env {
        name  = "TMP_BASE_PATH"
        value = "/tmp/cloudgeni"
      }
      
      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = "https://ai-amarildo4437ai637494179128.openai.azure.com/"
      }
      
      env {
        name  = "AZURE_OPENAI_DEPLOYMENT"
        value = "gpt-4o"
      }
      
      env {
        name  = "AZURE_API_KEY"
        value = ""
      }
      
      env {
        name  = "AZURE_API_BASE"
        value = ""
      }
      
      env {
        name  = "AZURE_API_VERSION"
        value = ""
      }
      
      env {
        name  = "GEMINI_API_KEY"
        value = ""
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull_beta
  ]
}

#############################
# Container App: Next.js Web App - Beta
#############################

resource "azurerm_user_assigned_identity" "nextjs_app_beta" {
  name                = "id-nextjs-app-beta"
  resource_group_name = azurerm_resource_group.rg_beta.name
  location            = azurerm_resource_group.rg_beta.location
}

resource "azurerm_container_app" "nextjs_app_beta" {
  name                         = "ca-nextjs-beta-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_beta.id
  resource_group_name          = azurerm_resource_group.rg_beta.name
  revision_mode               = "Single"
  max_inactive_revisions      = 100

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access_beta.id]  # Using beta environment ACR access identity
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access_beta.id
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
      image  = "${azurerm_container_registry.acrstaging.login_server}/web-app:${var.nextjs_app_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      
      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://api.beta.cloudgeni.ai"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://myadmin:Cloudgeni-2025!@psql-beta-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "NEXT_PUBLIC_URL"
        value = "https://beta.cloudgeni.ai"
      }
      
      env {
        name  = "NEXT_PUBLIC_COOKIE_DOMAIN"
        value = "beta.cloudgeni.ai"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull_beta
  ]
}

#############################
# Container App: Node API Service - Beta
#############################

resource "azurerm_container_app" "node_api_beta" {
  name                         = "ca-nodeapi-beta-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_beta.id
  resource_group_name          = azurerm_resource_group.rg_beta.name
  revision_mode               = "Single"
  max_inactive_revisions      = 100

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_access_beta.id]  # Using beta environment ACR access identity
  }

  registry {
    server   = azurerm_container_registry.acrstaging.login_server
    identity = azurerm_user_assigned_identity.acr_access_beta.id
  }

  ingress {
    external_enabled = true
    target_port     = 3001
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1
    
    container {
      name   = "node-server"
      image  = "${azurerm_container_registry.acrstaging.login_server}/node-server:${var.node_api_image}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      
      env {
        name  = "NODE_ENV"
        value = "cae-beta-neu"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@psql-beta-neu.postgres.database.azure.com:5432/cloudgeni?sslmode=require"
      }
      
      env {
        name  = "GITHUB_TOKEN"
        value = var.github_token
      }
      
      env {
        name  = "GITHUB_APP_ID"
        value = var.github_app_id
      }
      
      env {
        name  = "GITHUB_PRIVATE_KEY"
        value = var.github_private_key
      }
      
      env {
        name  = "API_KEY_OPENAI"
        value = var.openai_api_key
      }
      
      env {
        name  = "GOOGLE_CLIENT_ID"
        value = var.google_client_id
      }
      
      env {
        name  = "GOOGLE_CLIENT_SECRET"
        value = var.google_client_secret
      }
      
      env {
        name  = "GOOGLE_OAUTH_CALLBACK_URL"
        value = "https://api.beta.cloudgeni.ai/auth/google/callback"
      }
      
      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://api.beta.cloudgeni.ai"
      }
      
      env {
        name  = "NEXT_PUBLIC_URL"
        value = "https://beta.cloudgeni.ai"
      }
      
      env {
        name  = "GITHUB_APP_NAME"
        value = var.github_app_name
      }
      
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull_beta
  ]
}

#############################
# Container App: Langfuse - Beta
#############################

resource "azurerm_container_app" "langfuse_beta" {
  name                         = "ca-langfuse-beta-neu"
  container_app_environment_id = azurerm_container_app_environment.cae_beta.id
  resource_group_name         = azurerm_resource_group.rg_beta.name
  revision_mode               = "Single"

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
      name   = "langfuse"
      image  = var.langfuse_image
      cpu    = 1
      memory = "2Gi"

      env {
        name  = "PORT"
        value = "3000"
      }

      env {
        name  = "NEXTAUTH_SECRET"
        value = var.nextauth_secret
      }

      env {
        name  = "POSTGRES_PRISMA_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.beta.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "POSTGRES_URL_NON_POOLING"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.beta.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_user}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.beta.fqdn}:5432/cloudgeni?schema=langfuse&sslmode=require"
      }

      env {
        name  = "NEXTAUTH_URL"
        value = "https://ca-langfuse-beta-neu.${azurerm_container_app_environment.cae_beta.default_domain}"
      }

      env {
        name  = "SALT"
        value = var.langfuse_salt
      }

      env {
        name  = "TELEMETRY_ENABLED"
        value = "false"
      }

      env {
        name  = "CORS_ORIGIN"
        value = "*"
      }

      env {
        name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
        value = "true"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      template[0].container[0].env,
    ]
  }

  depends_on = [
    azurerm_container_registry.acrstaging,
    azurerm_role_assignment.acr_pull_beta,
    azurerm_postgresql_flexible_server.beta
  ]
}
