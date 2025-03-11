output "app_service_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sqldb.name
}

output "vm_id_eu" {
  description = "The ID of the newly created VM in EU region"
  value       = azurerm_linux_virtual_machine.vm_eu.id
}

output "vm_name_eu" {
  description = "The name of the VM in EU region"
  value       = azurerm_linux_virtual_machine.vm_eu.name
}