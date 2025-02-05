
resource "azurerm_storage_container" "source" {
  name                  = "source"
  storage_account_id    = data.azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "sp" {
  name                = "${var.project_name}-sp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags
  sku_name            = "Y1"
  os_type             = "Linux"
}

#resource "azurerm_app_service_plan" "sp" {
#  name                = "${var.project_name}-asp"
#  location            = var.location
#  resource_group_name = data.azurerm_resource_group.rg.name
#  kind                = "FunctionApp"
#  reserved            = true
#  tags                = var.tags
#
#  sku {
#    tier = "Dynamic"
#    size = "Y1"
#  }
#}

data "azurerm_resource_group" "rg" {
  name = "oym-deploy-sand-rg"
}

data "azurerm_storage_account" "sa" {
  name                = "oymdeploysandiacdl01"
  resource_group_name = data.azurerm_resource_group.rg.name
}
