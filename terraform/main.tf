/*
.Synopsis
    Main Bicep template for Azure Update Manager components.

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240613
*/

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
data "azurerm_client_config" "current" {}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// Locals and variables ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

locals {
  deploymentDate                       = formatdate("yyyyMMddHHmm", timestamp())
  azureUpdateManagerResourceGroupName  = var.azureUpdateManagerResourceGroupName == "" ? "az-${var.deploymentEnvironment}-update-manager-rg" : var.azureUpdateManagerResourceGroupName
  logAnalyticsWorkspaceName            = var.logAnalyticsWorkspaceName == "" ? "az-${var.deploymentEnvironment}-update-manager-law" : var.logAnalyticsWorkspaceName
  automationAccountName                = var.automationAccountName == "" ? "az-${var.deploymentEnvironment}-automation-aa" : var.automationAccountName
  automationAccountRunbooksLocationUri = var.automationAccountRunbooksLocationUri == "" ? "https://raw.githubusercontent.com/romanrabodzei/azure-update-manager/main" : var.automationAccountRunbooksLocationUri
  userAssignedIdentityName             = var.userAssignedIdentityName == "" ? "az-${var.deploymentEnvironment}-update-manager-mi" : var.userAssignedIdentityName
  maintenanceConfigName                = var.maintenanceConfigName == "" ? "az-${var.deploymentEnvironment}-update-manager-mc" : var.maintenanceConfigName
  maintenanceConfigAssignmentName      = var.maintenanceConfigAssignmentName == "" ? "az-${var.deploymentEnvironment}-update-manager-mca" : var.maintenanceConfigAssignmentName
  currentStartDate                     = formatdate("yyyy-MM-dd 00:00", timestamp())
  maintenanceStartTime                 = var.customStartDate == "" ? local.currentStartDate : "${var.customStartDate} 00:00"
  policyInitiativeName                 = var.policyInitiativeName == "" ? "az-${var.deploymentEnvironment}-update-manager-initiative" : var.policyInitiativeName
  tagValue                             = var.tagValue == "" ? var.deploymentEnvironment : var.tagValue
  tags                                 = { "${var.tagKey}" : local.tagValue }
}

variable "deploymentLocation" {
  type        = string
  description = "The location where the resources will be deployed."
  default     = "West Europe"
}

variable "deploymentEnvironment" {
  type        = string
  description = "The environment where the resources will be deployed."
  default     = "tfpoc"
}

variable "azureUpdateManagerResourceGroupName" {
  type        = string
  description = "The name of the resource group where the Azure Update Manager resources will be deployed."
  default     = ""
}

variable "logAnalyticsWorkspaceName" {
  type        = string
  description = "The name of the Log Analytics workspace."
  default     = ""
}

variable "logAnalyticsWorkspaceRetentionInDays" {
  type        = number
  description = "The retention period for the Log Analytics workspace."
  default     = 30
}

variable "logAnalyticsWorkspaceDailyQuotaGb" {
  type        = number
  description = "The daily quota for the Log Analytics workspace."
  default     = -1
}

variable "automationAccountName" {
  type        = string
  description = "The name of the Automation Account."
  default     = ""
}

variable "automationAccountRunbooksLocationUri" {
  type        = string
  description = "The URI of the Automation Account runbooks location."
  default     = ""
}

variable "userAssignedIdentityName" {
  type        = string
  description = "The name of the user-assigned identity."
  default     = ""
}

variable "maintenanceConfigName" {
  type        = string
  description = "The name of the maintenance configuration."
  default     = ""
}

variable "maintenanceConfigAssignmentName" {
  type        = string
  description = "The name of the maintenance configuration assignment."
  default     = ""
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
  default     = ""
}

variable "tagKey" {
  type    = string
  default = "environment"
}

variable "tagValue" {
  type    = string
  default = ""
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Resources //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource "azurerm_resource_group" "this_resource" {
  name     = local.azureUpdateManagerResourceGroupName
  location = var.deploymentLocation
  tags     = local.tags
}

module "managedIdentity_module" {
  source                      = "./resources/managedIdentity"
  deploymentLocation          = var.deploymentLocation
  userAssignedIdentityName    = local.userAssignedIdentityName
  deploymentResourceGroupName = azurerm_resource_group.this_resource.name
  tags                        = local.tags
}

module "logAnalyticsWorkspace_module" {
  source                               = "./resources/logAnalyticsWorkspace"
  deploymentResourceGroupName          = azurerm_resource_group.this_resource.name
  deploymentLocation                   = var.deploymentLocation
  logAnalyticsWorkspaceName            = local.logAnalyticsWorkspaceName
  automationAccountName                = local.automationAccountName
  automationAccountRunbooksLocationUri = local.automationAccountRunbooksLocationUri
  userAssignedIdentityName             = local.userAssignedIdentityName
  policyInitiativeName                 = local.policyInitiativeName
  tags                                 = local.tags
  depends_on = [ module.managedIdentity_module ]
}
