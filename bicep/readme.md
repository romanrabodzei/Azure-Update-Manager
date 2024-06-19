## Deployment parameters

The following table describes the parameters used in the deployment. The `Default value` column shows the default value used when the parameter is not provided.

| Parameter name                       | Description                  | Default value                                         |
| ------------------------------------ | ---------------------------- | ----------------------------------------------------- |
| deploymentLocation                   | Deployment location          | deployment().location                                 |
| deploymentEnvironment                | Deployment environment       | POC                                                   |
| azureUpdateManagerResourceGroupName  | Resource group name          | az-${deploymentEnvironment}-update-manager-rg         |
| logAnalyticsWorkspaceName            | Log Analytics workspace name | az-${deploymentEnvironment}-update-manager-law        |
| logAnalyticsWorkspaceRetentionInDays | Log Analytics retention days | 30                                                    |
| logAnalyticsWorkspaceDailyQuotaGb    | Log Analytics daily quota GB | -1                                                    |
| automationAccountName                | Automation account name      | az-${deploymentEnvironment}-update-manager-aa         |
| automationAccountRunbooksLocationUri | Runbooks location URI        | The repository URL                                    |
| userAssignedIdentityName             | User-assigned identity name  | az-${deploymentEnvironment}-update-manager-mi         |
| maintenanceConfigName                | Maintenance configuration    | az-${deploymentEnvironment}-update-manager-mc         |
| maintenanceConfigAssignmentName      | Maintenance assignment name  | az-${deploymentEnvironment}-update-manager-mca        |
| maintenanceStartDate                 | Maintenance start date       | Start date for maintenance window (yyyy-MM-dd format) |
| maintenanceStartDay                  | Maintenance start day        | Thursday                                              |
| policyInitiativeName                 | Policy initiative name       | az-${deploymentEnvironment}-update-manager-initiative |
| policyAssignmentName                 | Policy assignment name       | az-${deploymentEnvironment}-update-manager-assignment |
| tagKey                               | Tag Name                     | Environment                                           |
| tagValue                             | Tag Value                    | ${deploymentEnvironment}                              |
