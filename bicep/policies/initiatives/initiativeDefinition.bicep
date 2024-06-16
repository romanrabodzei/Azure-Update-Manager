/*
.Synopsis
    Main Bicep template for Initiative Deployment for Azure Update Manager

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240616
*/

targetScope = 'subscription'

param deploymentEnvironment string
param policyInitiativeName string
param userAssignedIdentitiesId string
param maintenanceConfigurationResourceId string

param tagKey string
param tagValue string
var tagsObject = { '${tagKey}': tagValue }
var tagsArray = [{ key: tagKey, value: tagValue }]

/// policies
module aum_policy_vms_should_check_for_missing_updates_module '../definitions/policy-vms_should_check_for_missing_updates.bicep' = {
  name: 'aum_policy_vms_should_check_for_missing_updates_module'
  params: {
    environment: deploymentEnvironment
  }
}

module aum_policy_set_prereq_for_updates_on_azure_vms_module '../definitions/policy-set_prereq_for_updates_on_azure_vms.bicep' = {
  name: 'aum_policy_set_prereq_for_updates_on_azure_vms_module'
  params: {
    environment: deploymentEnvironment
  }
}

module aum_policy_schedule_updates_using_update_manager '../definitions/policy-schedule_updates_using_update_manager.bicep' = {
  name: 'aum_policy_schedule_updates_using_update_manager'
  params: {
    environment: deploymentEnvironment
  }
}

module aum_policy_periodic_check_updates_on_azure_vms '../definitions/policy-periodic_check_updates_on_azure_vms.bicep' = {
  name: 'aum_policy_periodic_check_updates_on_azure_vms'
  params: {
    environment: deploymentEnvironment
  }
}

/// initiative
resource aum_initiative_def_01 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: toLower(policyInitiativeName)
  properties: {
    displayName: '${toUpper(deploymentEnvironment)}. Azure Update Management Initiative'
    description: 'Policy initiative definition that contains policy definitions for Azure Update Management'
    policyType: 'Custom'
    metadata: {
      category: 'Azure Update Manager'
      version: '1.0.240611'
    }
    parameters: {
      maintenanceConfigurationResourceId: {
        type: 'String'
        metadata: {
          displayName: 'Maintenance Configuration ARM ID'
          description: 'ARM ID of Maintenance Configuration which will be used for scheduling.'
        }
      }
      tagsObject: {
        type: 'Object'
        metadata: {
          displayName: 'Tags on machines'
          description: 'The list of tags that need to matched for getting target machines (case sensitive). Example: {"key": "value"}.'
        }
      }
      tagsArray: {
        type: 'Array'
        metadata: {
          displayName: 'Tags on machines'
          description: 'The list of tags that need to matched for getting target machines (case sensitive). Example: [ {"key": "tagKey1", "value": "value1"}, {"key": "tagKey2", "value": "value2"}].'
        }
      }
    }
    policyDefinitions: [
      {
        policyDefinitionId: aum_policy_periodic_check_updates_on_azure_vms.outputs.policyDefinitionId
        parameters: {
          tagValues: {
            value: '[parameters(\'tagsObject\')]'
          }
        }
      }
      {
        policyDefinitionId: aum_policy_schedule_updates_using_update_manager.outputs.policyDefinitionId
        parameters: {
          maintenanceConfigurationResourceId: {
            value: '[parameters(\'maintenanceConfigurationResourceId\')]'
          }
          tagValues: {
            value: '[parameters(\'tagsArray\')]'
          }
        }
      }
      {
        policyDefinitionId: aum_policy_set_prereq_for_updates_on_azure_vms_module.outputs.policyDefinitionId
        parameters: {
          tagValues: {
            value: '[parameters(\'tagsArray\')]'
          }
        }
      }
      {
        policyDefinitionId: aum_policy_vms_should_check_for_missing_updates_module.outputs.policyDefinitionId
        parameters: {
          tagValues: {
            value: '[parameters(\'tagsObject\')]'
          }
        }
      }
    ]
  }
}

/// assignment
resource aum_initiative_asgn_01 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: toLower('${deploymentEnvironment}-aum-initiative-asgn-01')
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentitiesId}': {}
    }
  }
  location: deployment().location
  properties: {
    displayName: '${toUpper(deploymentEnvironment)}. Azure Update Management Initiative Assignment'
    description: 'Azure Update Management Initiative Assignment'
    enforcementMode: 'Default'
    policyDefinitionId: aum_initiative_def_01.id
    notScopes: []
    parameters: {
      tagsObject: {
        value: tagsObject
      }
      tagsArray: {
        value: tagsArray
      }
      maintenanceConfigurationResourceId: {
        value: maintenanceConfigurationResourceId
      }
    }
  }
}
