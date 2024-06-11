<#
.Synopsis
    Runbook for Azure Policies remediations.

.DESCRIPTION
    The runbook will create policy remedation tasks for policies in Azure Update Manager initiatives.

.NOTES
    File Name  : createpolicyremedationtasksrunbook.ps1
    Author     : Roman Rabodzei
    Version    : 1.0.240611
#>

#region variables
$initiativeName = (Get-AutomationVariable -Name initiativeName)
$umiId = (Get-AutomationVariable -Name createPolicyRemedationTasksRunbook-umiId)
#endregion

#region RemediationTask function
function RemediationTask {
    param (
        [Parameter(Mandatory = $true)] $initiativeName,
        [Parameter(Mandatory = $true)] $policyAssignmentId,
        [Parameter(Mandatory = $true)] $policyDefinitionReferenceId
    )
    Write-Output "Creating remediation task..."
    Start-AzPolicyRemediation -Name ($initiativeName + "-" + $policyDefinitionReferenceId + "-remedation") `
        -PolicyDefinitionReferenceId $policyDefinitionReferenceId `
        -PolicyAssignmentId $policyAssignmentId
    Write-Output "Done.`n"
}
#endregion

#region Login to Azure
try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity -AccountId "$umiId"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

if ($null -eq (Get-AzContext).Subscription.Id) {
    try {
        Connect-AzAccount -EnvironmentName AzureUSGovernment -Identity -AccountId "$umiId"
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#endregion

#region Create remediation tasks
$policyDefinitionId = (Get-AzPolicySetDefinition -Name $initiativeName).PolicySetDefinitionId

$policyAssignmentId = (Get-AzPolicyAssignment -PolicyDefinitionId $policyDefinitionId).PolicyAssignmentId

$policyDefinitionReferenceIds = (Get-AzPolicySetDefinition -Name $initiativeName).Properties.PolicyDefinitions.policyDefinitionReferenceId

foreach ($policyDefinitionReferenceId in $policyDefinitionReferenceIds) {
    RemediationTask -initiativeName $initiativeName -policyAssignmentId $policyAssignmentId -policyDefinitionReferenceId $policyDefinitionReferenceId
}
#endregion