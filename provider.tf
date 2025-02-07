
provider "azurerm" {
  features {}
  subscription_id = "768bd339-512b-4cd4-9f0a-e2c6c03144ac"
}

provider "archive" {}

provider "null" {}

provider "random" {}

terraform {

  required_providers {

    azuread = {}

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">=2.7.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">=3.6.3"
    }
  }

  backend "azurerm" {
    resource_group_name  = "oym-deploy-sand-rg"
    storage_account_name = "oymdeploysandiacdl01"
    container_name       = "tfstate"
    key                  = "tests/sand.helloworld.tfstate"
  }
}
