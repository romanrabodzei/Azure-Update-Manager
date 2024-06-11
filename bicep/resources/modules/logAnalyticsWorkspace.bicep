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
param automationAccountRunbooksLocationUri string

param policyInitiativeName string
param userAssignedIdentityName string

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
}

resource logAnalyticsWorkspaceAutomation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  parent: logAnalyticsWorkspace_resource
  name: 'Automation'
  tags: tags
  properties: {
    resourceId: automationAccount_resource.id
  }
}

resource automationAccountRunbook_resource 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount_resource
  name: toLower('${automationAccountName}-runbook')
  location: location
  properties: {
    description: 'Runbook to create policy remediation tasks'
    runbookType: 'PowerShell'
    logVerbose: true
    logProgress: true
    logActivityTrace: 0
    publishContentLink: {
      uri: '${automationAccountRunbooksLocationUri}/scripts/createpolicyremedationtasksrunbook.ps1'
      contentHash: {
        algorithm: 'SHA256'
        value: '0x0'
      }
    }
  }
}

var automationAccountVariables = [
  { name: 'initiativeName', value: policyInitiativeName, isEncrypted: false }
  { name: 'umiId', value: userAssignedIdentity_resource.id, isEncrypted: true }
]

resource automationAccountVariable_resource 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = [
  for (object, i) in automationAccountVariables: {
    parent: automationAccount_resource
    name: automationAccountVariables[i].name
    properties: {
      value: automationAccountVariables[i].value
      isEncrypted: automationAccountVariables[i].isEncrypted
    }
  }
]

param currentDate string = utcNow('yyyy-MM-dd')
param currentDateParts array = split(currentDate, '-')
param year int = int(currentDateParts[0])
param month int = int(currentDateParts[1])
param day int = int(currentDateParts[2]) + 1

param nextDayAfterTheDeployment string = '${year}-${padLeft(string(month), 2, '0')}-${padLeft(string(day), 2, '0')}'

resource automationAccountSchedule_resource 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount_resource
  name: toLower('${automationAccountName}-schedule')
  properties: {
    description: 'Schedule to run the policy remediation tasks'
    startTime: '${nextDayAfterTheDeployment}T00:00:00+00:00'
    expiryTime: '9999-12-31T00:00:00+00:00'
    interval: '1'
    frequency: 'Day'
    timeZone: 'UTC'
  }
}

resource automationAccountJobSchedule_resource 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount_resource
  #disable-next-line BCP334
  name: toLower('${automationAccountName}-jobSchedule')
  properties: {
    runbook: {
      name: automationAccountRunbook_resource.name
    }
    schedule: {
      name: automationAccountSchedule_resource.name
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
