/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.OperationalInsights/workspaces?tabs=bicep#template-format
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.Automation/automationAccounts?tabs=bicep#template-format

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240616
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
param automationAccountPublicNetworkAccess bool = true
param automationAccountRunbooksLocationUri string

param policyInitiativeName string
param userAssignedIdentityName string

/// variables
param currentDate string = utcNow('yyyy-MM-dd')
var currentDateParts = split(currentDate, '-')
var year = int(currentDateParts[0])
var month = int(currentDateParts[1])
var day = int(currentDateParts[2]) + 1
var nextDayAfterTheDeployment = '${year}-${padLeft(string(month), 2, '0')}-${padLeft(string(day), 2, '0')}'

var automationAccountVariables = [
  { name: 'initiativeName', value: toLower(policyInitiativeName), isEncrypted: false }
  { name: 'umiId', value: userAssignedIdentity_resource.id, isEncrypted: true }
]

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

resource logAnalyticsWorkspaceAutomationAccount_link 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  parent: logAnalyticsWorkspace_resource
  name: toLower('Automation')
  tags: tags
  properties: {
    resourceId: automationAccount_resource.id
  }
}

resource userAssignedIdentity_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

resource automationAccount_resource 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: toLower(automationAccountName)
  location: location == 'eastus' ? 'eastus2' : location == 'eastus2' ? 'eastus' : location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity_resource.id}': {}
    }
  }
  properties: {
    sku: {
      name: automationAccountSku
    }
    publicNetworkAccess: automationAccountPublicNetworkAccess
  }
  resource runbook 'runbooks@2023-11-01' = {
    name: 'policyRemedationTasksRunbook'
    location: location
    tags: tags
    properties: {
      description: 'Runbook to create policy remediation tasks'
      runbookType: 'PowerShell'
      logProgress: true
      logVerbose: true
      publishContentLink: {
        uri: '${automationAccountRunbooksLocationUri}/scripts/policyRemedationTasksRunbook.ps1'
        version: '1.0.0'
      }
    }
  }
  resource variable 'variables' = [
    for (object, i) in automationAccountVariables: {
      name: automationAccountVariables[i].name
      properties: {
        value: '"${automationAccountVariables[i].value}"'
        isEncrypted: automationAccountVariables[i].isEncrypted
      }
    }
  ]
  resource schedule 'schedules' = {
    name: 'dailySchedule'
    properties: {
      description: 'Schedule to run the policy remediation tasks daily.'
      startTime: '${nextDayAfterTheDeployment}T00:00:00+00:00'
      expiryTime: '9999-12-31T00:00:00+00:00'
      interval: '1'
      frequency: 'Day'
      timeZone: 'UTC'
    }
  }
  resource jobSchedule 'jobSchedules' = {
    name: guid(uniqueString(subscription().subscriptionId), runbook.name, schedule.name)
    properties: {
      runbook: {
        name: runbook.name
      }
      schedule: {
        name: schedule.name
      }
    }
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
