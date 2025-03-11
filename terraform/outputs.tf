output "app_service_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sqldb.name
}
# Outputting new VM details
output "europe_vm" {
  value = azurerm_linux_virtual_machine.vm_eu.name
}


}}]}]}   Invalid JSON object needs resolution. The json above includes execution of TF instructions that repeat/need fixes poised___ . AI fixes incomplete multilige-debug Errors due configuration, but temporarily supplemental