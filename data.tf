data "azurerm_resource_group" "rg" {
  name = "oym-deploy-sand-rg"
}

data "archive_file" "functions_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

data "azurerm_storage_account" "sa" {
  name                = "oymdeploysandiacdl01"
  resource_group_name = data.azurerm_resource_group.rg.name
}