provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tf_backend_rg" {
  name     = "myBackendResourceGroup"
  location = "East US"
}

resource "azurerm_storage_account" "tf_backend_sa" {
  name                     = "mystorageaccount" # must be globally unique
  resource_group_name      = azurerm_resource_group.tf_backend_rg.name
  location                 = azurerm_resource_group.tf_backend_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tf_backend_sa.name
  container_access_type = "private"
}
