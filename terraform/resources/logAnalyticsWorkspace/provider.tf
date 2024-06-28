terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110"
    }
  }
}

data "azurerm_subscription" "current" {}