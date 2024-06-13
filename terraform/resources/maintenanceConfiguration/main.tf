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

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

/// variables
variable "deploymentResourceGroupName" {
  type = string
  description = "Deployment resource group name."
}

variable "deploymentLocation" {
  type = string
  description = "The location where the resources will be deployed."
}

variable "maintenanceConfigName" {
  type = string
  default = "Azure Update Manager Maintenance Configuration name."
}

variable "maintenanceStartDay" {
  type = string
  description = "The day of the week when the maintenance window starts."
}

variable "maintenanceStartTime" {
  type = string
  description = "The time of the day when the maintenance window starts."
}

variable "maintenanceVisibility" {
  type = string
  validation {
    condition     = var.maintenanceVisibility == "Public" || var.maintenanceVisibility == "Custom"
    error_message = "Value must be either 'Public' or 'Custom'"
  }
  default = "Custom"
}

variable "maintenanceRebootSetting" {
  type = string
  validation {
    condition     = var.maintenanceRebootSetting == "IfRequired" || var.maintenanceRebootSetting == "Never" || var.maintenanceRebootSetting == "Always"
    error_message = "Value must be either 'IfRequired', 'Never' or 'Always'"
  }
  default = "IfRequired"
}

variable "maintenanceScope" {
  type = string
  validation {
    condition     = var.maintenanceScope == "Extension" || var.maintenanceScope == "Host" || var.maintenanceScope == "InGuestPatch" || var.maintenanceScope == "OSImage" || var.maintenanceScope == "Resource" || var.maintenanceScope == "SQLDB" || var.maintenanceScope == "SQLManagedInstance"
    error_message = "Value must be either 'Extension', 'Host', 'InGuestPatch', 'OSImage', 'Resource', 'SQLDB' or 'SQLManagedInstance'"
  }
  default = "InGuestPatch"
}

/// tags
variable "tags" {
  type    = map(string)
  default = {}
}

/// resources
resource "azurerm_maintenance_configuration" "this_resource" {
  name                = var.maintenanceConfigName
  location            = var.deploymentLocation
  resource_group_name = var.deploymentResourceGroupName
  scope               = var.maintenanceScope
  install_patches {
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security", "UpdateRollup", "FeaturePack", "ServicePack", "Definition"]
    }
    reboot = var.maintenanceRebootSetting
  }
  in_guest_user_patch_mode = var.maintenanceScope == "InGuestPatch" ? "User" : null
  window {
    start_date_time      = var.maintenanceStartTime
    duration             = "03:55"
    time_zone            = "UTC"
    expiration_date_time = null
    recur_every          = "1Week ${var.maintenanceStartDay}"
  }
  visibility = var.maintenanceVisibility
  tags       = var.tags
}

/// outputs
output "maintenanceConfigurationId" {
  value = azurerm_maintenance_configuration.this_resource.id
}
