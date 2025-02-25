
resource "azurerm_eventhub_namespace" "main" {
  location            = var.location
  name                = "${var.project_name}-ehns"
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}

resource "azurerm_eventhub" "main" {
  namespace_id      = azurerm_eventhub_namespace.main.id
  name              = "${var.project_name}-eh"
  message_retention = 1
  partition_count   = 2
}

resource "azurerm_eventhub_consumer_group" "fa" {
  eventhub_name       = azurerm_eventhub.main.name
  name                = "${var.project_name}-cg"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = data.azurerm_resource_group.rg.name
}
