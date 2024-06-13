/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/maintenance_configuration

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

/// providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.107.0"
    }
  }
}

/// variable
variable "deploymentResourceGroupName" {
  type        = string
  description = "Deployment resource group name."
}

variable "deploymentLocation" {
  type        = string
  description = "The location where the resources will be deployed."
}

variable "maintenanceConfigurationId" {
  type        = string
  description = "The ID of the maintenance configuration."
}

variable "maintenanceConfigAssignmentName" {
  type        = string
  description = "The name of the maintenance configuration assignment."
}

variable "tagKey" {
  type = string
}

variable "tagValue" {
  type = string
}

/// resource
resource "azurerm_maintenance_assignment_dynamic_scope" "this_resource" {
  name                         = var.maintenanceConfigAssignmentName
  maintenance_configuration_id = var.maintenanceConfigurationId
  filter {
    resource_types = [
      "Microsoft.Compute/virtualMachines"
    ]
    resource_groups = []
    os_types = [
      "Windows",
      "Linux"
    ]
    locations = [
      var.deploymentLocation
    ]
    tag_filter = "All"
    tags {
      tag = var.tagKey
      values = [
        var.tagValue
      ]
    }
  }

}
