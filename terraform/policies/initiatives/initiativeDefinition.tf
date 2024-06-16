/*
.Synopsis
    Bicep template for Log Analytics Workspace, Automation account.
    Template:
      - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240613
*/

/// locals
locals {
  tagsObject = {
    "${var.tagKey}" : "${var.tagValue}"
  }
  tagArray = [
    {
      key   = "${var.tagKey}",
      value = "${var.tagValue}"
    }
  ]
}

/// variables
variable "deploymentEnvironment" {
  type        = string
  description = "The environment where the resources will be deployed."
}

variable "deploymentLocation" {
  type        = string
  description = "The location where the resources will be deployed."

}

variable "policyInitiativeName" {
  type        = string
  description = "The name of the policy initiative."
}

variable "userAssignedIdentitiesId" {
  type        = string
  description = "The ID of the user assigned identities."
}

variable "maintenanceConfigurationResourceId" {
  type        = string
  description = "The ID of the maintenance configuration."
}

variable "tagKey" {
  type = string
}

variable "tagValue" {
  type = string
}

/// resources
module "policyDefinitions_module" {
  source                = "../definitions"
  deploymentEnvironment = var.deploymentEnvironment
}

resource "azurerm_policy_set_definition" "this_resource" {
  name         = var.policyInitiativeName
  display_name = "${upper(var.deploymentEnvironment)}. Azure Update Management Initiative"
  description  = "Policy initiative definition that contains policy definitions for Azure Update Management"
  policy_type  = "Custom"
  metadata     = <<METADATA
  {
    "category": "Azure Update Manager",
    "version": "1.0.240613"
  }
METADATA
  parameters   = <<PARAMETERS
  {
    "maintenanceConfigurationResourceId": {
      "type" : "String",
      "metadata" : {
        "displayName" : "Maintenance Configuration ARM ID",
        "description" : "ARM ID of Maintenance Configuration which will be used for scheduling."
      }
    },
    "tagsObject" : {
      "type" : "Object",
      "metadata" : {
        "displayName" : "Tags on machines",
        "description" : "The list of tags that need to matched for getting target machines (case sensitive). Example: {\"key\": \"value\"}."
      }
    },
    "tagsArray" : {
      "type" : "Array",
      "metadata" : {
        "displayName" : "Tags on machines",
        "description" : "The list of tags that need to matched for getting target machines (case sensitive). Example: [ {\"key\": \"tagKey1\", \"value\": \"value1\"}, {\"key\": \"tagKey2\", \"value\": \"value2\"}]."
      }
    }
  }
PARAMETERS
  policy_definition_reference {
    policy_definition_id = module.policyDefinitions_module.aum_policy_periodic_check_updates_on_azure_vms_policy_definition_id
    parameter_values     = <<VALUE
    {
      "tagValues": {
        "value": "[parameters('tagsObject')]"
      }
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = module.policyDefinitions_module.aum_policy_schedule_updates_using_update_manager_policy_definition_id
    parameter_values     = <<VALUE
    {
      "maintenanceConfigurationResourceId": {
        "value": "[parameters('maintenanceConfigurationResourceId')]"
      },
      "tagValues": {
        "value": "[parameters('tagsArray')]"
      }
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = module.policyDefinitions_module.aum_policy_set_prereq_for_updates_on_azure_vms_policy_definition_id
    parameter_values     = <<VALUE
    {
      "tagValues": {
        "value": "[parameters('tagsArray')]"
      }
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = module.policyDefinitions_module.aum_policy_vms_should_check_for_missing_updates_policy_definition_id
    parameter_values     = <<VALUE
    {
      "tagValues": {
        "value": "[parameters('tagsObject')]"
      }
    }
    VALUE
  }
}

resource "azurerm_subscription_policy_assignment" "this_resource" {
  name            = "${var.deploymentEnvironment}-aum-initiative-asgn-01"
  display_name    = "${upper(var.deploymentEnvironment)}. Azure Update Management Initiative Assignment"
  description     = "Azure Update Management Initiative Assignment"
  subscription_id = data.azurerm_subscription.current.id
  location        = var.deploymentLocation
  identity {
    type         = "UserAssigned"
    identity_ids = [var.userAssignedIdentitiesId]
  }
  enforce              = true
  policy_definition_id = azurerm_policy_set_definition.this_resource.id
  parameters           = <<PARAMETERS
  {
    "tagsObject" : {
      "value" : ${jsonencode(local.tagsObject)}
    },
    "tagsArray" : {
      "value" : ${jsonencode(local.tagArray)}
    },
    "maintenanceConfigurationResourceId" : {
      "value" : "${var.maintenanceConfigurationResourceId}"
    }
  }
PARAMETERS
}
