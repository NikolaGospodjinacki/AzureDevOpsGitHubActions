terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "rg-proto-common-westeurope-01"
      storage_account_name = "stprotocommonweu01"
      container_name       = "terraform-proto-common-westeurope-01"
      key                  = "terraform.tfstate"
  }

}

provider "azurerm" {
  features {}
}