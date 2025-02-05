
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/../function_src"
  output_path = "${path.module}/../function_src.zip"

  depends_on = [null_resource.pip]
}

resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${path.module}/../function_src/requirements.txt")}"
  }
  provisioner "local-exec" {
    command     = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = "${path.module}/../function_src"
  }
}

resource "azurerm_storage_container" "function_releases" {
  name                 = "function-releases"
  storage_account_id = data.azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = "function-${substr(data.archive_file.function.output_md5, 0, 6)}.zip"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.function_releases.name
  type                   = "Block"
  content_md5            = data.archive_file.function.output_md5
  source                 = "${path.module}/../function_src.zip"
}

resource "azurerm_linux_function_app" "fa" {
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.sp.id
  location            = var.location

  storage_account_name       = data.azurerm_storage_account.sa.name
  storage_account_access_key = data.azurerm_storage_account.sa.primary_access_key
  functions_extension_version = "~4"
  name                       = "${var.project_name}-fa"
  tags                       = var.tags

  site_config {
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
  }
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = data.azurerm_storage_account.sa.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_linux_function_app.fa.identity.0.principal_id
  skip_service_principal_aad_check = true
}
