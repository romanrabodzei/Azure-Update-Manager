/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity

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

/// locals
locals {
  nextDayAfterTheDeployment = formatdate("YYYY-MM-DD", timeadd(timestamp(), "24h"))
  automationAccountVariables = [
    {
      name  = "initiativeName"
      value = var.policyInitiativeName
      encrypted = false
    },
    {
      name  = "umiId"
      value = data.azurerm_user_assigned_identity.this_resource.id
      encrypted = true
    }
  ]
}

/// variables
variable "deploymentResourceGroupName" {
  type = string
}

variable "deploymentLocation" {
  type = string
}

variable "logAnalyticsWorkspaceName" {
  type = string
}

variable "logAnalyticsWorkspaceSku" {
  type    = string
  default = "PerGB2018"
}

variable "logAnalyticsWorkspaceRetentionInDays" {
  type    = number
  default = 30
}

variable "logAnalyticsWorkspaceDailyQuotaGb" {
  type    = number
  default = -1
}

variable "logAnalyticsWorkspacePublicNetworkAccess" {
  type    = bool
  default = true
  validation {
    condition     = var.logAnalyticsWorkspacePublicNetworkAccess == true || var.logAnalyticsWorkspacePublicNetworkAccess == false
    error_message = "The value must be 'true' or 'false'."
  }
}

variable "automationAccountName" {
  type = string
}

variable "automationAccountSku" {
  type    = string
  default = "Basic"
}

variable "automationAccountPublicNetworkAccess" {
  type    = bool
  default = true
  validation {
    condition     = var.automationAccountPublicNetworkAccess == true || var.automationAccountPublicNetworkAccess == false
    error_message = "The value must be 'true' or 'false'."
  }
}

variable "automationAccountRunbooksLocationUri" {
  type = string
}

variable "userAssignedIdentityName" {
  type        = string
  description = "The user assigned identity name."
}

variable "policyInitiativeName" {
  type        = string
  description = "Policy Initiative Name for Automation Account runbook variables."
}

/// tags
variable "tags" {
  type = map(string)
}

/// resources
resource "azurerm_log_analytics_workspace" "this_resource" {
  name                       = lower(var.logAnalyticsWorkspaceName)
  location                   = var.deploymentLocation
  resource_group_name        = var.deploymentResourceGroupName
  tags                       = var.tags
  sku                        = var.logAnalyticsWorkspaceSku
  retention_in_days          = var.logAnalyticsWorkspaceRetentionInDays
  internet_ingestion_enabled = var.logAnalyticsWorkspacePublicNetworkAccess
  internet_query_enabled     = var.logAnalyticsWorkspacePublicNetworkAccess
  daily_quota_gb             = var.logAnalyticsWorkspaceDailyQuotaGb
}

resource "azurerm_log_analytics_linked_service" "this_resource" {
  resource_group_name = var.deploymentResourceGroupName
  workspace_id        = azurerm_log_analytics_workspace.this_resource.id
  read_access_id      = azurerm_automation_account.this_resource.id
}

data "azurerm_user_assigned_identity" "this_resource" {
  name                = var.userAssignedIdentityName
  resource_group_name = var.deploymentResourceGroupName
}

resource "azurerm_automation_account" "this_resource" {
  name                = lower(var.automationAccountName)
  location            = var.deploymentLocation
  resource_group_name = var.deploymentResourceGroupName
  tags                = var.tags
  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.this_resource.id]
  }
  sku_name                      = var.automationAccountSku
  public_network_access_enabled = var.automationAccountPublicNetworkAccess
}

resource "azurerm_automation_runbook" "this_resource" {
  automation_account_name = azurerm_automation_account.this_resource.name
  name                    = "policyRemedationTasksRunbook"
  location                = var.deploymentLocation
  resource_group_name     = var.deploymentResourceGroupName
  tags                    = var.tags
  runbook_type            = "PowerShell"
  log_progress            = true
  log_verbose             = true
  publish_content_link {
    uri = "${var.automationAccountRunbooksLocationUri}/scripts/policyRemedationTasksRunbook.ps1"
  }
}

resource "azurerm_automation_variable_string" "this_resource" {
  automation_account_name = azurerm_automation_account.this_resource.name
  resource_group_name     = var.deploymentResourceGroupName
  name                    = each.value.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  for_each                = { for v in local.automationAccountVariables : v.name => v }
}

resource "azurerm_automation_schedule" "this_resource" {
  automation_account_name = azurerm_automation_account.this_resource.name
  resource_group_name     = var.deploymentResourceGroupName
  name                    = "dailySchedule"
  description             = "Schedule to run the policy remediation tasks daily."
  start_time              = "${local.nextDayAfterTheDeployment}T00:00:00+00:00"
  expiry_time             = "9999-12-31T00:00:00+00:00"
  interval                = 1
  frequency               = "Day"
  timezone                = "UTC"
}

resource "azurerm_automation_job_schedule" "this_resource" {
  automation_account_name = azurerm_automation_account.this_resource.name
  resource_group_name     = var.deploymentResourceGroupName
  runbook_name            = azurerm_automation_runbook.this_resource.name
  schedule_name           = azurerm_automation_schedule.this_resource.name
}

resource "azurerm_monitor_diagnostic_setting" "this_resource" {
  name               = lower("send-data-to-${var.logAnalyticsWorkspaceName}")
  target_resource_id = azurerm_automation_account.this_resource.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this_resource.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}