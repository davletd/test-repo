# variables.tf
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "cloudgeni-test-resource-group"
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
  default     = "cloudgeni-test-appservice"
}

variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
  default     = "cloudgeni-test-sqlserver"
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "cloudgeni-test-database"
}

variable "location" {
  description = "Azure location for resources"
  type        = string
  default     = "North Europe"
}

variable "client_id" {
  description = "Azure Active Directory Application (client) ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Active Directory Application (client) Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Active Directory Tenant ID"
  type        = string
  default     = "00c2299a-6609-4944-bc5a-88e811aca06e"
}

variable "sql_admin_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "The environment for the resource group (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "sql_connection_string" {
  description = "SQL connection string for the web app"
  type        = string
  default     = ""
}

variable "sql_audit_storage_account_name" {
  type        = string
  description = "The name of the storage account for SQL audit logs."
  default     = "sqlauditsa"
}

variable "sql_audit_storage_account_access_key" {
  type        = string
  description = "The access key for the SQL audit storage account."
  sensitive   = true
  # Note: It is recommended to use a more secure way to manage access keys, such as Azure Key Vault.
  # For this example, we will use a placeholder. Please replace with a real access key or a secure retrieval method.
  default     = "PLEASE_REPLACE_WITH_A_REAL_ACCESS_KEY"
}
