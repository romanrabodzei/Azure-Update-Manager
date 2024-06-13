/*
.Synopsis
    Bicep template for Azure Update Management Maintenance Configuration.
    Template:
      - https://docs.microsoft.com/en-us/azure/templates/Microsoft.Maintenance/maintenanceConfigurations?tabs=bicep#template-format

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

/// parameters
param location string

param maintenanceConfigName string

param maintenanceStartDay string
param maintenanceStartTime string

@allowed(['Custom', 'Public'])
param maintenanceVisibility string = 'Custom'

@allowed(['Always', 'IfRequired', 'Never'])
param maintenanceReboot string = 'IfRequired'

@allowed(['Extension', 'Host', 'InGuestPatch', 'OSImage', 'Resource', 'SQLDB', 'SQLManagedInstance'])
param maintenanceScope string = 'InGuestPatch'

var maintenanceExtensionProperties_InGuestPatch = { InGuestPatchMode: 'User' }

param tags object = {}

/// resources
resource maintenanceConfiguration 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' = {
  name: toLower(maintenanceConfigName)
  location: location
  tags: tags
  properties: {
    maintenanceScope: maintenanceScope
    installPatches: {
      linuxParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
        packageNameMasksToExclude: []
        packageNameMasksToInclude: []
      }
      windowsParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
          'UpdateRollup'
          'FeaturePack'
          'ServicePack'
          'Definition'
        ]
        kbNumbersToExclude: []
        kbNumbersToInclude: []
      }
      rebootSetting: maintenanceReboot
    }
    extensionProperties: maintenanceScope == 'InGuestPatch' ? maintenanceExtensionProperties_InGuestPatch : {}
    maintenanceWindow: {
      startDateTime: maintenanceStartTime
      duration: '03:55'
      timeZone: 'UTC'
      expirationDateTime: null
      recurEvery: '1Week ${maintenanceStartDay}'
    }
    visibility: maintenanceVisibility
  }
}

/// output
output maintenanceConfigurationId string = maintenanceConfiguration.id
