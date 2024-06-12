/*
.Synopsis
    Main Bicep template for Azure Update Manager components.

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "=0.4.0"
    }
  }
}

provider "azapi" {
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// Locals and variables ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

locals {
  deploymentDate       = formatdate("yyyyMMddHHmm", timestamp())
  currentStartDate     = formatdate("yyyy-MM-dd 00:00", timestamp())
  maintenanceStartTime = var.customStartDate == "" ? local.currentStartDate : "${var.customStartDate} 00:00"

  tags = {
    var.tagKey : var.tagValue
  }
}

variable "deploymentLocation" {
  type        = string
  description = "The location where the resources will be deployed."
}

variable "deploymentEnvironment" {
  type        = string
  description = "The environment where the resources will be deployed."
}

variable "azureUpdateManagerResourceGroupName" {
  type        = string
  description = "The name of the resource group where the Azure Update Manager resources will be deployed."
  default     = "az-${deploymentEnvironment}-update-manager-law"
}

variable "logAnalyticsWorkspaceName" {
  type        = string
  description = "The name of the Log Analytics workspace."
  default     = "az-${deploymentEnvironment}-update-manager-law"
}

variable "logAnalyticsWorkspaceRetentionInDays" {
  type        = number
  description = "The retention period for the Log Analytics workspace."
  default     = 30
}

variable "logAnalyticsWorkspaceDailyQuotaGb" {
  type        = number
  description = "The daily quota for the Log Analytics workspace."
  default     = 1
}

variable "automationAccountName" {
  type        = string
  description = "The name of the Automation Account."
  default     = "az-${deploymentEnvironment}-automation-aa"
}

variable "automationAccountRunbooksLocationUri" {
  type        = string
  description = "The URI of the Automation Account runbooks location."
  default     = "https://raw.githubusercontent.com/romanrabodzei/azure-update-manager/main"
}

variable "userAssignedIdentityName" {
  type        = string
  description = "The name of the user-assigned identity."
  default     = "az-${deploymentEnvironment}-update-manager-mi"
}

variable "maintenanceConfigName" {
  type        = string
  description = "The name of the maintenance configuration."
  default     = "az-${deploymentEnvironment}-update-manager-mc"
}

variable "maintenanceConfigAssignmentName" {
  type        = string
  description = "The name of the maintenance configuration assignment."
  default     = "az-${deploymentEnvironment}-update-manager-mca"
}

variable "customStartDate" {
  type        = string
  description = "The custom start date for the maintenance configuration assignment."
  default     = ""
}

variable "maintenanceStartDay" {
  type        = string
  description = "Custom start day for maintenance window. If not provided, Thursday is used."
  default     = "Thursday"
}

variable "policyInitiativeName" {
  type        = string
  description = "The name of the policy initiative."
  default     = "az-${deploymentEnvironment}-update-manager-initiative"
}

variable "tagKey" {
  type    = string
  default = "environment"
}

variable "tagValue" {
  type    = string
  default = var.deploymentEnvironment
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Resources //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

data "azurerm_client_config" "current" {}

resource "azapi_resource" "resourceGroup_resource" {
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  parent_id = data.azurerm_client_config.current.subscription_id
  name      = var.azureUpdateManagerResourceGroupName
  location  = var.deploymentLocation
  tags      = local.tags
}
