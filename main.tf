# For function and plan names. To avoid issues with automatically 
# created artifacts, when deploying always using the same names.
resource "random_string" "random" {
  length    = 4
  lower     = true
  min_lower = 4
}
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
resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${path.module}/functions/requirements.txt")}"
  }
  provisioner "local-exec" {
    command     = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = "${path.module}/functions"
  }
}
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
  depends_on  = [null_resource.pip]
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
  name                = "${var.project_name}-${random_string.random.id}-asp"
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
  # Note: this will automatically define the function env variable AzureWebJobsStorage.
  # Note: storage_account_access_key conflicts with storage_uses_managed_identity.
  storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
  name                       = "${var.project_name}-${random_string.random.id}-fa"
  tags                       = var.tags
  builtin_logging_enabled = false
  functions_extension_version = "~4"
  site_config {
    use_32_bit_worker = false
    application_stack {
      python_version = "3.9"
    }
    application_insights_key = azurerm_application_insights.app-insights.instrumentation_key
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "WEBSITE_RUN_FROM_PACKAGE"       = var.remote_build ? null : azurerm_storage_blob.storage_blob_function.url
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = var.remote_build ? true : null
    
    # Instead of the below, the function should rather use AzureWebJobsStorage, automatically setup by TF.
    #"MyStorageConnectionAppSetting"  = data.azurerm_storage_account.storage_account.primary_connection_string
    # This is actually automatically set by terraform by defining application_insights_key in the site_config block.
    #"APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app-insights.instrumentation_key
  }
}
resource "null_resource" "func_deploy" {
  provisioner "local-exec" {
    command = (
      var.remote_build ?
      <<-EOT
      az functionapp deployment source config-zip \
      --resource-group ${data.azurerm_resource_group.resource_group.name} \
      --name ${azurerm_linux_function_app.function-app.name} \
      --src functions.zip \
      --build-remote true
      EOT
    : "echo 'Local function build: no further commands needed.'") # run command only if remote_build
    working_dir = path.module
  }
  depends_on = [azurerm_linux_function_app.function-app]
}
resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.storage_account.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_linux_function_app.function-app.identity.0.principal_id
  skip_service_principal_aad_check = true
}