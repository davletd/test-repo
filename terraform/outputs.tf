output "app_service_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sqldb.name
}

output "vm_public_ip" {
  description = "Public IP address of the Virtual Machine (if applicable)"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_id" {
  description = "ID of the created Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.id
}
