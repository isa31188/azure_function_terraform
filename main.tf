
resource "azurerm_application_insights" "app-insights" {
  application_type    = "web"
  location            = var.location
  name                = "${var.project_name}-ai"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  tags                = var.tags
}

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

resource "azurerm_storage_container" "storage_container_function" {
  name               = "function-releases"
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_storage_container" "source" {
  name               = "source"
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

resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-asp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  os_type             = "Linux"
  tags                = var.tags
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "function-app" {
  resource_group_name = data.azurerm_resource_group.resource_group.name
  service_plan_id     = azurerm_service_plan.main.id
  location            = var.location

  storage_account_name       = data.azurerm_storage_account.storage_account.name
  storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
  name                       = "${var.project_name}-fa"
  tags                       = var.tags

  builtin_logging_enabled = false

  functions_extension_version = "~4"

  site_config {
    use_32_bit_worker = false
    application_stack {
      python_version = "3.9"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = azurerm_storage_blob.storage_blob_function.url
    "MyStorageConnectionAppSetting" : data.azurerm_storage_account.storage_account.primary_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app-insights.instrumentation_key
  }
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.storage_account.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_linux_function_app.function-app.identity.0.principal_id
  skip_service_principal_aad_check = true
}
