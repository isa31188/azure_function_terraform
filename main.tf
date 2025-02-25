
resource "azurerm_storage_container" "function_releases" {
  name               = "function-releases"
  storage_account_id = data.azurerm_storage_account.sa.id
}

resource "azurerm_storage_blob" "functions_zip" {
  name                   = "functions-${substr(data.archive_file.functions_zip.output_md5, 0, 6)}.zip"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.function_releases.name
  type                   = "Block"
  content_md5            = data.archive_file.functions_zip.output_md5
  source                 = "${path.module}/functions.zip"
}

resource "azurerm_application_insights" "ai" {
  application_type    = "web"
  location            = var.location
  name                = "${var.project_name}-ai"
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags
}

#resource "azurerm_role_assignment" "role_assignment_storage" {
#  scope                            = data.azurerm_storage_account.sa.id
#  role_definition_name             = "Storage Blob Data Contributor"
#  principal_id                     = azurerm_function_app.function-app.identity.0.principal_id
#  skip_service_principal_aad_check = true
#}
