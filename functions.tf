
# For function and plan names. To avoid issues with automatically 
# created artifacts, when deploying always using the same names.
resource "random_string" "random" {
  length    = 4
  lower     = true
  min_lower = 4
}

resource "azurerm_service_plan" "sp" {
  name                = "${var.project_name}-${random_string.random.id}-asp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = "Linux"
  tags                = var.tags
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "function-app" {
  resource_group_name  = data.azurerm_resource_group.rg.name
  service_plan_id      = azurerm_service_plan.sp.id
  location             = var.location
  storage_account_name = data.azurerm_storage_account.sa.name
  # Note: this will automatically define the function env variable AzureWebJobsStorage.
  # Note: storage_account_access_key conflicts with storage_uses_managed_identity.
  storage_account_access_key  = data.azurerm_storage_account.sa.primary_access_key
  name                        = "${var.project_name}-${random_string.random.id}-fa"
  tags                        = var.tags
  builtin_logging_enabled     = false
  functions_extension_version = "~4"
  site_config {
    use_32_bit_worker = false
    application_stack {
      python_version = "3.9"
    }
    application_insights_key = azurerm_application_insights.ai.instrumentation_key
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "WEBSITE_RUN_FROM_PACKAGE"       = var.remote_build ? null : azurerm_storage_blob.functions_zip.url
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = var.remote_build ? true : null
    "EventHubConnectionString"       = azurerm_eventhub_namespace.main.default_primary_connection_string
  }
  connection_string {
    name  = "EventHubConnectionString"
    type  = "EventHub"
    value = azurerm_eventhub_namespace.main.default_primary_connection_string
  }
}

resource "null_resource" "func_deploy" {
  triggers = {
    function_zip_md5 = data.archive_file.functions_zip.output_md5
  }
  provisioner "local-exec" {
    command = (
      var.remote_build ?
      <<-EOT
      az functionapp deployment source config-zip \
      --resource-group ${data.azurerm_resource_group.rg.name} \
      --name ${azurerm_linux_function_app.function-app.name} \
      --src functions.zip \
      --build-remote true
      EOT
    : "echo 'Local function build: no further commands needed.'") # run command only if remote_build
    working_dir = path.module
  }
  depends_on = [
    azurerm_linux_function_app.function-app,
    azurerm_storage_blob.functions_zip
  ]
}

resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${path.module}/functions/requirements.txt")}"
  }
  provisioner "local-exec" {
    command     = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = "${path.module}/functions"
  }
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.sa.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_linux_function_app.function-app.identity.0.principal_id
  skip_service_principal_aad_check = true
}