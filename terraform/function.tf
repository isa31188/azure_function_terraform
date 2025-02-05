
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/../functions"
  output_path = "${path.module}/../functions.zip"

  depends_on = [null_resource.pip]
}

resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${path.module}/functions/requirements.txt")}"
  }
  provisioner "local-exec" {
    command     = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = "${path.module}/../functions"
  }
}

resource "azurerm_storage_container" "storage_container_function" {
  name                 = "function-releases"
  storage_account_name = data.azurerm_storage_account.sa.name
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = "functions-${substr(data.archive_file.function.output_md5, 0, 6)}.zip"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = data.azurerm_storage_container.sa.name
  type                   = "Block"
  content_md5            = data.archive_file.function.output_md5
  source                 = "${path.module}/functions.zip"
}

resource "azurerm_linux_function_app" "fa" {
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.sp.id
  location            = var.location

  storage_account_name       = data.azurerm_storage_account.sa.name
  storage_account_access_key = data.azurerm_storage_account.sa.primary_access_key
  name                       = "${var.project_name}-fa"
  tags                       = var.tags

  enable_builtin_logging = false
  os_type                = "linux"
  version                = "4"

  site_config {
    linux_fx_version          = "PYTHON|3.9"
    use_32_bit_worker_process = false
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "WEBSITE_RUN_FROM_PACKAGE"       = azurerm_storage_blob.storage_blob_function.url
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app-insights.instrumentation_key
  }
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.sa.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_function_app.fa.identity.0.principal_id
  skip_service_principal_aad_check = true
}
