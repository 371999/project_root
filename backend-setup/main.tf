provider "azurerm" {
  features {}
  client_id       = "dd2f42db-9fe4-4d32-9593-cdf7e597b07a"
  client_secret   = "1mf8Q~N2x1sM_TiFDKCABEGVTgzlPVgCnyZFQb8b"
  subscription_id = "cd06d49d-6ae2-4d2b-82e4-50b2b98f55dd"
  tenant_id       = "ed27b597-cea0-4942-8c6f-40e6a78bf47d"
}

# Random string generator for unique storage account name suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tf_backend_rg" {
  name     = "myBackendResourceGroup"
  location = "East US"
}

resource "azurerm_storage_account" "tf_backend_sa" {
  name                     = "mystorageaccount${random_string.suffix.result}" # Globally unique name
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

output "storage_account_name" {
  value = azurerm_storage_account.tf_backend_sa.name
}

output "storage_container_name" {
  value = azurerm_storage_container.tfstate_container.name
}
