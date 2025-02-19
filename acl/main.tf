
data "azurerm_resource_group" "resource_group" {
  name = "oym-deploy-sand-rg"
}

data "azurerm_storage_account" "storage_account" {
  name                = "oymdeploysandiacdl01"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_storage_container" "storage_container_function" {
  name               = "temp-folder"
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_storage_blob" "test_file_level0" {
  name                   = "testfile.txt"
  storage_account_name   = data.azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_function.name
  type                   = "Block"
  source                 = "${path.module}/testfile.txt"
}

resource "azurerm_storage_blob" "test_file_level1" {
  name                   = "subfolder/testfile.txt"
  storage_account_name   = data.azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_function.name
  type                   = "Block"
  source                 = "${path.module}/testfile.txt"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "test_level0" {
  name               = azurerm_storage_container.storage_container_function.name
  storage_account_id = data.azurerm_storage_account.storage_account.id

  ace {
    scope       = "default"
    type        = "user"
    id          = "48726ecc-0b40-40e6-b735-08a10fd7e24b"
    permissions = "rwx"
  }
}