
resource "azurerm_storage_container" "source" {
  name                 = "source"
  storage_account_name = data.azurerm_storage_account.sa.name
}

resource "azurerm_service_plan" "sp" {
  name                = "${var.project_name}-sp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved            = true
  tags                = var.tags
  sku_name            = "Y1"
}

data "azurerm_resource_group" "rg" {
  name = "oym-deploy-sand-rg"
}

data "azurerm_storage_account" "sa" {
  name = "oymdeploysandiacdl01"
}
