/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleDefinitions?tabs=bicep#template-format

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240611
*/

/// deploymentScope
targetScope = 'subscription'

/// parameters
param roleDefinitionId string
param userAssignedIdentityClientId string

/// resources
resource roleDefinition_resource 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitionId
  scope: subscription()
}

resource roleAssignment_resource 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleDefinition_resource.id)
  scope: subscription()
  properties: {
    principalId: userAssignedIdentityClientId
    roleDefinitionId: roleDefinition_resource.id
  }
}
