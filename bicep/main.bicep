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

@description('The location where the resources will be deployed.')
param deploymentLocation string = deployment().location
@description('The environment where the resources will be deployed.')
param deploymentEnvironment string
@description('The UTC date and time when the deployment is executed.')
param deploymentDate string = utcNow('yyyyMMddHHmm')

@description('Name of the resource group for the Azure Update Manager components.')
param azureUpdateManagerResourceGroupName string = 'az-${deploymentEnvironment}-update-manager-rg'

@description('Name of the Log Analytics workspace.')
param logAnalyticsWorkspaceName string = 'az-${deploymentEnvironment}-update-manager-law'
param logAnalyticsWorkspaceRetentionInDays int = 30
param logAnalyticsWorkspaceDailyQuotaGb int = -1

@description('Name of the automation account.')
param automationAccountName string = 'az-${deploymentEnvironment}-update-manager-aa'
param automationAccountRunbooksLocationUri string = 'https://raw.githubusercontent.com/romanrabodzei/azure-update-manager/main'

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
@description('The name of the policy initiative.')
param policyInitiativeName string = 'az-${deploymentEnvironment}-update-manager-initiative'

/// tags
param tagKey string = 'environment'
param tagValue string = deploymentEnvironment
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

module logAnalyticsWorkspace_module 'resources/loganalyticsworkspace.bicep' = {
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

module managedIdentity_module 'resources/managedIdentity.bicep' = {
  scope: resourceGroup_resource
  name: toLower('managedIdentity-${deploymentDate}')
  params: {
    location: deploymentLocation
    userAssignedIdentityName: userAssignedIdentityName
    tags: tags
  }
}

module roleAssignment_module 'resources/roleAssignmentSubscriptionScope.bicep' = {
  name: toLower('roleAssignment-${deploymentDate}')
  params: {
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    userAssignedIdentityClientId: managedIdentity_module.outputs.userAssignedIdentityClientId
  }
  dependsOn: [
    managedIdentity_module
  ]
}

module maintenanceConfiguration_module 'resources/maintenanceConfigurations.bicep' = {
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

module configurationAssignment_module 'resources/configurationAssignments.bicep' = {
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Policies ///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

module policies_module 'policies/initiatives/uss-initiative-def-aum-01.bicep' = {
  name: toLower('policies-${deploymentDate}')
  params: {
    deploymentEnvironment: deploymentEnvironment
    policyInitiativeName: policyInitiativeName
    userAssignedIdentitiesId: managedIdentity_module.outputs.userAssignedIdentityId
    maintenanceConfigurationResourceId: maintenanceConfiguration_module.outputs.maintenanceConfigurationId
    tagKey: tagKey
    tagValue: tagValue
  }
}
