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