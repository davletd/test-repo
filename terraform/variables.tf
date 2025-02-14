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

variable "vm_name" {
  description = "Name of the Virtual Machine"
  type        = string
  default     = "cloudgeni-test-vm"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "vm_admin_username" {
  description = "Admin Username for the Virtual Machine"
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin Password for the Virtual Machine"
  type        = string
  sensitive   = true
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "cloudgeni-test-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Address prefix for the Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

