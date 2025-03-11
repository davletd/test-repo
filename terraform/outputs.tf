output "app_service_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sqldb.name
}
output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}