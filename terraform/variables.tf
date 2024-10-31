variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "cloudgeni-resource-group"
}

variable "app_service_name" {
  description = "Name of the App Service"
  default     = "cloudgeni-appservice"
}

variable "sql_server_name" {
  description = "Name of the SQL Server"
  default     = "cloudgeni-sqlserver"
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
  default     = "cloudgenidatabase"
}

variable "location" {
  description = "Azure location for resources"
  default     = "North Europe"
}

variable "client_id" {
  description = "Azure Active Directory Application (client) ID"
  type        = string
  default     =  "${AZURE_CLIENT_ID}"
}

variable "client_secret" {
  description = "Azure Active Directory Application (client) Secret"
  type        = string
  sensitive   = true
  default     = "${AZURE_CLIENT_SECRET}"
}

variable "tenant_id" {
  description = "Azure Active Directory Tenant ID"
  type        = string
  default     = "00c2299a-6609-4944-bc5a-88e811aca06e" #"8768eef3-ca99-471c-956b-7d1ab5a4da8a"  # Replace with your actual Tenant ID
}

variable "sql_admin_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
  default     = "EFoYPr!Kw27qMa3Y-qNp37HC"  # Replace with a secure password
}