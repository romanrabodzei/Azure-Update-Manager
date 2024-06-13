/// module providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.107.0"
    }
  }
}

/// variable
variable "deploymentEnvironment" {
  type        = string
  description = "Deployment resource group name."
}