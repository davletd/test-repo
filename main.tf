
resource "azurerm_storage_account" "stamarildo" {
  name                     = "stamarildo44637494179128"
  resource_group_name      = "rg-amarildo-3329_ai"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  allow_blob_public_access     = false
  shared_access_key_enabled    = false
}
