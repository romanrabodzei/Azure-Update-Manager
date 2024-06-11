/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.OperationalInsights/workspaces?tabs=bicep#template-format
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.Automation/automationAccounts?tabs=bicep#template-format

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

/// deploymentScope
targetScope = 'resourceGroup'

/// parameters
param location string

param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceSku string = 'pergb2018'
param logAnalyticsWorkspaceRetentionInDays int = 30
param logAnalyticsWorkspaceDailyQuotaGb int = -1
@allowed([
  'Enabled'
  'Disabled'
])
param logAnalyticsWorkspacePublicNetworkAccess string = 'Enabled'

param automationAccountName string
param automationAccountSku string = 'Basic'
@allowed([
  true
  false
])
param automationAccountPublicNetworkAccess bool = false
@secure()
param userAssignedIdentityId string

/// tags
param tags object = {}

/// resources
resource logAnalyticsWorkspace_resource 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: toLower(logAnalyticsWorkspaceName)
  location: location
  tags: tags
  properties: {
    sku: {
      name: logAnalyticsWorkspaceSku
    }
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    publicNetworkAccessForIngestion: logAnalyticsWorkspacePublicNetworkAccess
    publicNetworkAccessForQuery: logAnalyticsWorkspacePublicNetworkAccess
    workspaceCapping: {
      dailyQuotaGb: logAnalyticsWorkspaceDailyQuotaGb
    }
  }
}

resource automationAccount_resource 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location == 'eastus' ? 'eastus2' : location == 'eastus2' ? 'eastus' : location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    sku: {
      name: automationAccountSku
    }
    publicNetworkAccess: automationAccountPublicNetworkAccess
  }
}

resource logAnalyticsWorkspaceAutomation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  parent: logAnalyticsWorkspace_resource
  name: 'Automation'
  tags: tags
  properties: {
    resourceId: automationAccount_resource.id
  }
}

resource send_data_to_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: automationAccount_resource
  name: toLower('send-data-to-${logAnalyticsWorkspaceName}')
  properties: {
    workspaceId: logAnalyticsWorkspace_resource.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
