/*
.Synopsis
    Main Bicep template for Azure Update Manager components.

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////// Deployment scope /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'subscription'

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// Parameters and variables ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Deployment location.')
param deploymentLocation string = deployment().location
param deploymentEnvironment string = 'Dev'
param deploymentDate string = utcNow('yyyyMMddHHmm')

@description('Name of the resource group for the Azure Update Manager components.')
param azureUpdateManagerResourceGroupName string = 'az-${deploymentEnvironment}-update-manager-rg'

@description('Name of the Log Analytics workspace.')
param logAnalyticsWorkspaceName string = 'az-${deploymentEnvironment}-update-manager-law'
param logAnalyticsWorkspaceRetentionInDays int = 30
param logAnalyticsWorkspaceDailyQuotaGb int = -1

@description('Name of the automation account.')
param automationAccountName string = 'az-${deploymentEnvironment}-update-manager-aa'
param automationAccountRunbooksLocationUri string = 'https://raw.githubusercontent.com/romanrabodzei/azure-update-manager/develop'

@description('Name of the user-assigned managed identity.')
param userAssignedIdentityName string = 'az-${deploymentEnvironment}-update-manager-mi'

@description('Name of the maintenance configuration.')
param maintenanceConfigName string = 'az-${deploymentEnvironment}-update-manager-mc'

@description('Name of the maintenance configuration assignment.')
param maintenanceConfigAssignmentName string = 'az-${deploymentEnvironment}-update-manager-mca'

@description('Custom start date for maintenance window. If not provided, current date is used.')
param customStartDate string = ''
param currentStartDate string = utcNow('yyyy-MM-dd 00:00')
var maintenanceStartTime = customStartDate == '' ? currentStartDate : '${customStartDate} 00:00'

@description('Custom start day for maintenance window. If not provided, Thursday is used.')
param maintenanceStartDay string = 'Thursday'

param policyInitiativeName string = 'az-${deploymentEnvironment}-update-manager-initiative'

/// tags
param tagKey string = 'Environment'
@allowed(['Dev', 'Prod'])
param tagValue string = 'Dev'
var tags = {
  '${tagKey}': tagValue
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Resources //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource resourceGroup_resource 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: toLower(azureUpdateManagerResourceGroupName)
  location: deploymentLocation
  tags: tags
}

module logAnalyticsWorkspace_module './modules/loganalyticsworkspace.bicep' = {
  scope: resourceGroup_resource
  name: toLower('logAnalyticsWorkspace-${deploymentDate}')
  params: {
    location: deploymentLocation
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceRetentionInDays: logAnalyticsWorkspaceRetentionInDays
    logAnalyticsWorkspaceDailyQuotaGb: logAnalyticsWorkspaceDailyQuotaGb
    automationAccountName: automationAccountName
    automationAccountRunbooksLocationUri: automationAccountRunbooksLocationUri
    policyInitiativeName: policyInitiativeName
    userAssignedIdentityName: userAssignedIdentityName
    tags: tags
  }
  dependsOn: [managedIdentity_module]
}

module managedIdentity_module './modules/managedIdentity.bicep' = {
  scope: resourceGroup_resource
  name: toLower('managedIdentity-${deploymentDate}')
  params: {
    location: deploymentLocation
    userAssignedIdentityName: userAssignedIdentityName
    tags: tags
  }
}

module roleAssignment_module './modules/roleAssignmentSubscriptionScope.bicep' = {
  name: toLower('roleAssignment-${deploymentDate}')
  params: {
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    userAssignedIdentityClientId: managedIdentity_module.outputs.userAssignedIdentityClientId
  }
  dependsOn: [
    managedIdentity_module
  ]
}

module maintenanceConfiguration_module './modules/maintenanceConfigurations.bicep' = {
  scope: resourceGroup_resource
  name: toLower('maintenanceConfiguration-${deploymentDate}')
  params: {
    maintenanceConfigName: maintenanceConfigName
    location: deploymentLocation
    maintenanceStartTime: maintenanceStartTime
    maintenanceStartDay: maintenanceStartDay
    maintenanceReboot: 'IfRequired'
    tags: tags
  }
}

module configurationAssignment_module './modules/configurationAssignments.bicep' = {
  name: toLower('configurationAssignment-${deploymentDate}')
  params: {
    maintenanceConfigName: maintenanceConfigName
    maintenanceConfigResourceGroupName: azureUpdateManagerResourceGroupName
    maintenanceConfigAssignmentName: maintenanceConfigAssignmentName
    tagKey: tagKey
    tagValue: tagValue
  }
  dependsOn: [
    maintenanceConfiguration_module
  ]
}


