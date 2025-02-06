
resource "azurerm_application_insights" "app-insights" {
  application_type    = "web"
  location            = var.location
  name                = "${var.project_name}-ai"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  tags                = var.tags
}

#data "azurerm_resource_group" "rg" {
#  name     = "niels-zeilemaker-sandbox"
#}

data "azurerm_resource_group" "resource_group" {
  name = "oym-deploy-sand-rg"
}

data "azurerm_storage_account" "storage_account" {
  name                = "oymdeploysandiacdl01"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

#resource "azurerm_storage_account" "storage_account_function" {
#  name                     = "st${var.owner}${var.project_name}fn"
#  resource_group_name      = data.azurerm_resource_group.rg.name
#  location                 = var.location
#  account_tier             = "standard"
#  account_replication_type = "LRS"
#  account_kind             = "StorageV2"
#  is_hns_enabled           = true
#  tags                     = var.tags
#}

resource "azurerm_storage_container" "storage_container_function" {
  name = "function-releases"
  #storage_account_name = data.azurerm_storage_account.storage_account.name
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_storage_container" "source" {
  name = "source"
  #storage_account_name = data.azurerm_storage_account.storage_account.name
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = "functions-${substr(data.archive_file.function.output_md5, 0, 6)}.zip"
  storage_account_name   = data.azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_function.name
  type                   = "Block"
  content_md5            = data.archive_file.function.output_md5
  source                 = "${path.module}/functions.zip"
}

#resource "azurerm_eventhub_namespace" "main" {
#  location            = var.location
#  name                = "eh-${var.owner}-${var.project_name}-datadog"
#  resource_group_name = data.azurerm_resource_group.rg.name
#  sku                 = "Standard"
#  capacity            = 1
#  tags                = var.tags
#}
#resource "azurerm_eventhub" "main" {
#  namespace_name      = azurerm_eventhub_namespace.main.name
#  resource_group_name = data.azurerm_resource_group.rg.name
#  name                = "events"
#  message_retention   = 1
#  partition_count     = 2
#}
#resource "azurerm_eventhub_consumer_group" "fa" {
#  eventhub_name       = azurerm_eventhub.main.name
#  name                = "fa"
#  namespace_name      = azurerm_eventhub_namespace.main.name
#  resource_group_name = data.azurerm_resource_group.rg.name
#}

#resource "azurerm_application_insights" "app-insights" {
#  application_type    = "web"
#  location            = var.location
#  name                = "app-${var.owner}-${var.project_name}"
#  resource_group_name = data.azurerm_resource_group.rg.name
#  tags                = var.tags
#}

resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-asp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  os_type             = "Linux"
  tags                = var.tags
  sku_name            = "Y1"
}

resource "azurerm_function_app" "function-app" {
  resource_group_name = data.azurerm_resource_group.resource_group.name
  app_service_plan_id = azurerm_service_plan.main.id
  location            = var.location

  storage_account_name       = data.azurerm_storage_account.storage_account.name
  storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
  name                       = "${var.project_name}-fa"
  tags                       = var.tags

  enable_builtin_logging = false
  os_type                = "linux"
  version                = "~4"

  site_config {
    linux_fx_version          = "PYTHON|3.9"
    use_32_bit_worker_process = false
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    #"EventHub_AccessKey"         = azurerm_eventhub_namespace.main.default_primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE" = azurerm_storage_blob.storage_blob_function.url
    #"APPINSIGHTS_INSTRUMENTATIONKEY"           = azurerm_application_insights.app-insights.instrumentation_key
    "MyStorageConnectionAppSetting" : data.azurerm_storage_account.storage_account.primary_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app-insights.instrumentation_key
  }
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.storage_account.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_function_app.function-app.identity.0.principal_id
  skip_service_principal_aad_check = true
}
