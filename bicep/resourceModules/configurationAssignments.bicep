/*
.Synopsis
    Bicep template for Azure Update Management Maintenance Configuration.
    Template:
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.Maintenance/configurationAssignments?tabs=bicep#template-format

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

targetScope = 'subscription'

/// parameters
param maintenanceConfigName string
param maintenanceConfigAssignmentName string
param maintenanceConfigResourceGroupName string

param tagKey string = ''
param tagValue string = ''
var tagSettings = {
  filterOperator: 'All'
  tags: {
    '${tagKey}': [
      '${tagValue}'
    ]
  }
}

/// resources
resource maintenanceConfiguration 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' existing = {
  scope: resourceGroup(maintenanceConfigResourceGroupName)
  name: maintenanceConfigName
}

resource configurationAssignment_resource 'Microsoft.Maintenance/configurationAssignments@2023-04-01' = {
  name: toLower(maintenanceConfigAssignmentName)
  properties: {
    maintenanceConfigurationId: maintenanceConfiguration.id
    #disable-next-line use-resource-id-functions
    resourceId: subscription().id
    filter: {
      resourceTypes: [
        'Microsoft.Compute/virtualMachines'
      ]
      resourceGroups: []
      osTypes: [
        'Windows'
        'Linux'
      ]
      locations: [
        deployment().location
      ]
      tagSettings: tagKey != '' && tagValue != '' ? tagSettings : {}
    }
  }
}
