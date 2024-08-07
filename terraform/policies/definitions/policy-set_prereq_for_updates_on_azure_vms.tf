/*
.Synopsis
    Terraform template for Azure Policy Definition.
    Template:
      - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition

.NOTES
    Author     : Roman Rabodzei
    Version    : 1.0.240613
*/

/// resource
resource "azurerm_policy_definition" "aum_policy_set_prereq_for_updates_on_azure_vms" {
  name         = "${var.deploymentEnvironment}-aum-policy-set_prereq_for_updates_on_azure_vms"
  display_name = "Set prerequisite for Scheduling recurring updates on Azure virtual machines."
  description  = "This policy will set the prerequisite needed to schedule recurring updates on Azure Update Manager by configuring patch orchestration to \"Customer Managed Schedules\". This change will automatically set the patch mode to \"AutomaticByPlatform\" and enables \"BypassPlatformSafetyChecksOnUserSchedule\" to \"True\" on Azure VMs. The prerequisite is not applicable for Arc-enabled servers. Learn more - https://learn.microsoft.com/en-us/azure/update-manager/dynamic-scope-overview?tabs=avms#prerequisites"
  policy_type  = "Custom"
  mode         = "All"
  metadata     = <<METADATA
  {
    "category": "Azure Update Manager",
    "version": "1.0.240613"
  }
METADATA
  parameters   = <<PARAMETERS
  {
    "resourceGroups": {
      "type": "Array",
      "metadata": {
        "displayName": "Resource groups",
        "description": "The list of resource groups from which machines need to be targeted. Example: [\"rg1\", \"rg2\"]. Adding no resource group here would target all resource groups in the scope."
      },
      "defaultValue": []
    },
    "operatingSystemTypes": {
      "type": "Array",
      "metadata": {
        "displayName": "Operating System types",
        "description": "The list of Operating System types from which machines need to be targeted. Adding no operating system types here would target all operating system types in the scope."
      },
      "allowedValues": [
        "Windows",
        "Linux"
      ],
      "defaultValue": [
        "Windows",
        "Linux"
      ]
    },
    "locations": {
      "type": "Array",
      "metadata": {
        "displayName": "Machines locations",
        "description": "The list of locations from which machines need to be targeted. Adding no locations here would target all locations in the scope.",
        "strongType": "location"
      },
      "defaultValue": []
    },
    "tagValues": {
      "type": "Array",
      "metadata": {
        "displayName": "Tags on machines",
        "description": "The list of tags that need to matched for getting target machines (case sensitive). Example: [ {\"key\": \"tagKey1\", \"value\": \"value1\"}, {\"key\": \"tagKey2\", \"value\": \"value2\"}]."
      },
      "defaultValue": []
    },
    "tagOperator": {
      "type": "String",
      "metadata": {
        "displayName": "Tags operator",
        "description": "Matching condition for resource tags"
      },
      "allowedValues": [
        "All",
        "Any"
      ],
      "defaultValue": "Any"
    },
    "effect": {
      "type": "String",
      "metadata": {
        "displayName": "Effect",
        "description": "Enable or disable the execution of the policy"
      },
      "allowedValues": [
        "DeployIfNotExists",
        "Disabled"
      ],
      "defaultValue": "DeployIfNotExists"
    }
  }
PARAMETERS
  policy_rule  = <<POLICY_RULE
  {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
        },
        {
          "anyOf": [
            {
              "value": "[empty(parameters('operatingSystemTypes'))]",
              "equals": true
            },
            {
              "allOf": [
                {
                  "anyOf": [
                    {
                      "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
                      "in": "[parameters('operatingSystemTypes')]"
                    },
                    {
                      "allOf": [
                        {
                          "value": "Linux",
                          "in": "[parameters('operatingSystemTypes')]"
                        },
                        {
                          "field": "Microsoft.Compute/imageOffer",
                          "in": [
                            "sles-standard",
                            "sles-sapcal",
                            "sles-sap-byos",
                            "sles-sap",
                            "sles-byos",
                            "sles-15-sp4-sapcal",
                            "sles-15-sp4-basic",
                            "sles-15-sp4",
                            "sles-15-sp3-sapcal",
                            "sles-15-sp2-hpc",
                            "sles-15-sp2-basic",
                            "sles-15-sp1-sapcal",
                            "sles",
                            "sle-hpc-15-sp4",
                            "sles-12-sp5",
                            "sles-15-sp2",
                            "centos-hpc",
                            "centos-ci",
                            "centos-lvm",
                            "Centos",
                            "rhel-sap-ha",
                            "rhel-sap-apps",
                            "RHEL-RAW",
                            "RHEL",
                            "aml-workstation",
                            "aks",
                            "oracle-database-19-3",
                            "oracle-database",
                            "oracle-linux",
                            "cbl-mariner",
                            "0001-com-ubuntu-server-jammy",
                            "0001-com-ubuntu-pro-jammy",
                            "0001-com-ubuntu-pro-focal",
                            "0001-com-ubuntu-server-focal",
                            "0001-com-ubuntu-pro-bionic",
                            "UbuntuServer"
                          ]
                        }
                      ]
                    },
                    {
                      "allOf": [
                        {
                          "value": "Windows",
                          "in": "[parameters('operatingSystemTypes')]"
                        },
                        {
                          "field": "Microsoft.Compute/imageOffer",
                          "in": [
                            "WindowsServer",
                            "microsoftserveroperatingsystems-previews",
                            "windowsserverhotpatch-previews",
                            "sql2016sp1-ws2016",
                            "sql2016sp2-ws201",
                            "sql2017-ws2016",
                            "sql2019-ws2019",
                            "dynamics",
                            "process-server"
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "anyOf": [
            {
              "value": "[empty(parameters('locations'))]",
              "equals": true
            },
            {
              "field": "location",
              "in": "[parameters('locations')]"
            }
          ]
        },
        {
          "anyOf": [
            {
              "value": "[empty(parameters('resourceGroups'))]",
              "equals": true
            },
            {
              "value": "[resourceGroup().name]",
              "in": "[parameters('resourceGroups')]"
            }
          ]
        },
        {
          "anyOf": [
            {
              "value": "[empty(parameters('tagValues'))]",
              "equals": true
            },
            {
              "allOf": [
                {
                  "value": "[empty(field('tags'))]",
                  "equals": false
                },
                {
                  "value": "[parameters('tagOperator')]",
                  "equals": "Any"
                },
                {
                  "count": {
                    "value": "[parameters('tagValues')]",
                    "name": "tagKvp",
                    "where": {
                      "value": "[length(intersection(createObject(current('tagKvp').key, current('tagKvp').value), field('tags')))]",
                      "greater": 0
                    }
                  },
                  "greater": 0
                }
              ]
            },
            {
              "allOf": [
                {
                  "value": "[empty(field('tags'))]",
                  "equals": false
                },
                {
                  "value": "[parameters('tagOperator')]",
                  "equals": "All"
                },
                {
                  "count": {
                    "value": "[parameters('tagValues')]",
                    "name": "tagKvp",
                    "where": {
                      "value": "[length(intersection(createObject(current('tagKvp').key, current('tagKvp').value), field('tags')))]",
                      "greater": 0
                    }
                  },
                  "equals": "[length(parameters('tagValues'))]"
                }
              ]
            }
          ]
        },
        {
          "allOf": [
            {
              "field": "Microsoft.Compute/imagePublisher",
              "notEquals": "microsoft-ads"
            },
            {
              "anyOf": [
                {
                  "field": "Microsoft.Compute/imagePublisher",
                  "equals": "Canonical"
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftcblmariner"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "cbl-mariner"
                    },
                    {
                      "field": "Microsoft.Compute/imageSKU",
                      "in": [
                        "cbl-mariner-1",
                        "1-gen2",
                        "cbl-mariner-2",
                        "cbl-mariner-2-gen2"
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "oracle"
                    },
                    {
                      "anyOf": [
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "oracle-linux"
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "in": [
                                    "8",
                                    "8-ci",
                                    "81",
                                    "81-ci",
                                    "81-gen2"
                                  ]
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "ol7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "ol8*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "ol9*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "ol9-lvm*"
                                }
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "oracle-database"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "oracle_db_21"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "like": "oracle-database-*"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "like": "18.*"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "oracle-database-19-3"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "oracle-database-19-0904"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoft-aks"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "aks"
                    },
                    {
                      "field": "Microsoft.Compute/imageSKU",
                      "equals": "aks-engine-ubuntu-1804-202112"
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoft-dsvm"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "aml-workstation"
                    },
                    {
                      "field": "Microsoft.Compute/imageSKU",
                      "in": [
                        "ubuntu-20",
                        "ubuntu-20-gen2"
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "Redhat"
                    },
                    {
                      "anyOf": [
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "RHEL"
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "8*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "9*"
                                }
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "notEquals": "74-gen2"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "RHEL-RAW"
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "8*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "9*"
                                }
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "rhel-sap-ha"
                              ]
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "equals": "90sapha-gen2"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "8*"
                                }
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "notEquals": "7.5"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "rhel-sap-apps"
                              ]
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "equals": "90sapha-gen2"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "8*"
                                }
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "like": "rhel-sap-*"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "9_0"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "rhel-ha"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "like": "8*"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "notIn": [
                                "7.4",
                                "7.5",
                                "7.6",
                                "8.1",
                                "81_gen2"
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "rhel-sap"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "notIn": [
                                "7.4",
                                "7.5",
                                "7.7"
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "like": "7*"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "OpenLogic"
                    },
                    {
                      "allOf": [
                        {
                          "anyOf": [
                            {
                              "allOf": [
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "equals": "Centos"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "like": "7*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "notLike": "8*"
                                }
                              ]
                            },
                            {
                              "allOf": [
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "equals": "centos-lvm"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "in": [
                                    "7-lvm",
                                    "8-lvm",
                                    "7-lvm-gen2"
                                  ]
                                }
                              ]
                            },
                            {
                              "allOf": [
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "equals": "centos-ci"
                                },
                                {
                                  "field": "Microsoft.Compute/imageSKU",
                                  "equals": "7-ci"
                                }
                              ]
                            }
                          ]
                        },
                        {
                          "field": "Microsoft.Compute/imageOffer",
                          "notEquals": "centos-hpc"
                        }
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "SUSE"
                    },
                    {
                      "anyOf": [
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "sles-12-sp5",
                                "sles-15-sp2",
                                "sle-hpc-15-sp4",
                                "sles-15-sp1-sapcal",
                                "sles-15-sp3-sapcal",
                                "sles-15-sp4-basic",
                                "sles-15-sp4"
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "in": [
                                "gen1",
                                "gen2"
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "sles",
                                "sles-standard"
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "12-sp4-gen2"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "sles-15-sp2-basic",
                                "sles-15-sp2-hpc"
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "gen2"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "sles-15-sp4-sapcal"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "gen1"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "in": [
                                "sles-byos",
                                "sles-sap"
                              ]
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "in": [
                                "12-sp4",
                                "12-sp4-gen2"
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "sles-sap-byos"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "in": [
                                "12-sp4",
                                "12-sp4-gen2",
                                "gen2-12-sp4"
                              ]
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "sles-sapcal"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "12-sp3"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "like": "gen*"
                            },
                            {
                              "anyOf": [
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "like": "opensuse-leap-15-*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "like": "sles-12-sp5-*"
                                },
                                {
                                  "field": "Microsoft.Compute/imageOffer",
                                  "like": "sles-sap-12-sp5*"
                                },
                                {
                                  "allOf": [
                                    {
                                      "field": "Microsoft.Compute/imageOffer",
                                      "like": "sles-sap-15-*"
                                    },
                                    {
                                      "field": "Microsoft.Compute/imageOffer",
                                      "notLike": "sles-sap-15-*-byos"
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "MicrosoftWindowsServer"
                    },
                    {
                      "anyOf": [
                        {
                          "field": "Microsoft.Compute/imageOffer",
                          "in": [
                            "windowsserver",
                            "windows-cvm",
                            "windowsserverdotnet",
                            "windowsserver-gen2preview",
                            "windowsserversemiannual",
                            "windowsserverupgrade"
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "microsoftserveroperatingsystems-previews"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "windows-server-vnext-azure-edition-core"
                            }
                          ]
                        },
                        {
                          "allOf": [
                            {
                              "field": "Microsoft.Compute/imageOffer",
                              "equals": "windowsserverhotpatch-previews"
                            },
                            {
                              "field": "Microsoft.Compute/imageSKU",
                              "equals": "windows-server-2022-azure-edition-hotpatch"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "MicrosoftSQLServer"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "notLike": "sql2019-sles*"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "notIn": [
                        "sql2019-rhel7",
                        "sql2017-rhel7"
                      ]
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftdynamicsax"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "dynamics"
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftazuresiterecovery"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "process-server"
                    },
                    {
                      "field": "Microsoft.Compute/imageSKU",
                      "equals": "windows-2012-r2-datacenter"
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftbiztalkserver"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "biztalk-server"
                    }
                  ]
                },
                {
                  "field": "Microsoft.Compute/imagePublisher",
                  "equals": "microsoftpowerbi"
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftsharepoint"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "microsoftsharepointserver"
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftwindowsserverhpcpack"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "equals": "windowsserverhpcpack"
                    }
                  ]
                },
                {
                  "allOf": [
                    {
                      "field": "Microsoft.Compute/imagePublisher",
                      "equals": "microsoftvisualstudio"
                    },
                    {
                      "field": "Microsoft.Compute/imageOffer",
                      "like": "visualstudio*"
                    },
                    {
                      "anyOf": [
                        {
                          "field": "Microsoft.Compute/imageSKU",
                          "like": "*-ws2012r2"
                        },
                        {
                          "field": "Microsoft.Compute/imageSKU",
                          "like": "*-ws2016"
                        },
                        {
                          "field": "Microsoft.Compute/imageSKU",
                          "like": "*-ws2019"
                        },
                        {
                          "field": "Microsoft.Compute/imageSKU",
                          "like": "*-ws2022"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    "then": {
      "effect": "[parameters('effect')]",
      "details": {
        "roleDefinitionIds": [
          "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "type": "Microsoft.Compute/virtualMachines",
        "name": "[field('name')]",
        "evaluationDelay": "AfterProvisioningSuccess",
        "existenceCondition": {
          "anyOf": [
            {
              "allOf": [
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration",
                  "exists": true
                },
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration.patchSettings.automaticByPlatformSettings.bypassPlatformSafetyChecksOnUserSchedule",
                  "equals": true
                },
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration.patchSettings.patchMode",
                  "equals": "AutomaticByPlatform"
                }
              ]
            },
            {
              "allOf": [
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration",
                  "exists": true
                },
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.patchSettings.automaticByPlatformSettings.bypassPlatformSafetyChecksOnUserSchedule",
                  "equals": true
                },
                {
                  "field": "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.patchSettings.patchMode",
                  "equals": "AutomaticByPlatform"
                }
              ]
            }
          ]
        },
        "deployment": {
          "properties": {
            "mode": "incremental",
            "parameters": {
              "machineResourceId": {
                "value": "[field('id')]"
              },
              "osType": {
                "value": "[field('Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType')]"
              },
              "imagePublisher": {
                "value": "[tolower(field('Microsoft.Compute/imagePublisher'))]"
              },
              "imageOffer": {
                "value": "[tolower(field('Microsoft.Compute/imageOffer'))]"
              },
              "location": {
                "value": "[field('location')]"
              }
            },
            "template": {
              "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
              "contentVersion": "1.0.0.0",
              "parameters": {
                "machineResourceId": {
                  "type": "string"
                },
                "osType": {
                  "type": "String"
                },
                "imagePublisher": {
                  "type": "string"
                },
                "imageOffer": {
                  "type": "string"
                },
                "location": {
                  "type": "string"
                }
              },
              "variables": {
                "allowedWindowsPublishers": [
                  "microsoftwindowsserver",
                  "microsoftsqlserver",
                  "microsoftdynamicsax",
                  "microsoftazuresiterecovery",
                  "microsoftbiztalkserver",
                  "microsoftpowerbi",
                  "microsoftsharepoint",
                  "microsoftwindowsserverhpcpack",
                  "microsoftvisualstudio"
                ],
                "imagePublisher": "[parameters('imagePublisher')]",
                "imageOffer": "[parameters('imageOffer')]",
                "osTypeFromAllowedListOfPublishers": "[if(contains(variables('allowedWindowsPublishers'), variables('imagePublisher')), 'windows', 'linux')]",
                "osTypeFromPublisher": "[if(equals(variables('imagePublisher'), 'microsoftsqlserver'), if(contains(variables('imageOffer'), 'ws'), 'windows', 'linux'), variables('osTypeFromAllowedListOfPublishers'))]",
                "osType": "[toLower(if(empty(parameters('osType')), variables('osTypeFromPublisher'), parameters('osType')))]",
                "automaticByPlatformPatchMode": "AutomaticByPlatform",
                "linuxOSProfile": {
                  "linuxConfiguration": {
                    "patchSettings": {
                      "patchMode": "[variables('automaticByPlatformPatchMode')]",
                      "automaticByPlatformSettings": {
                        "bypassPlatformSafetyChecksOnUserSchedule": true
                      }
                    }
                  }
                },
                "windowsOSProfile": {
                  "windowsConfiguration": {
                    "patchSettings": {
                      "patchMode": "[variables('automaticByPlatformPatchMode')]",
                      "automaticByPlatformSettings": {
                        "bypassPlatformSafetyChecksOnUserSchedule": true
                      }
                    }
                  }
                },
                "machineName": "[last(split(parameters('machineResourceId'), '/'))]",
                "updatedOSProfile": "[if(equals(variables('osType'), 'windows'), variables('windowsOSProfile'), variables('linuxOSProfile'))]"
              },
              "resources": [
                {
                  "type": "Microsoft.Compute/virtualMachines",
                  "apiVersion": "2023-03-01",
                  "name": "[variables('machineName')]",
                  "location": "[parameters('location')]",
                  "properties": {
                    "osProfile": "[variables('updatedOSProfile')]"
                  }
                }
              ],
              "outputs": {
                "OSProfile": {
                  "type": "object",
                  "value": "[variables('updatedOSProfile')]"
                }
              }
            }
          }
        }
      }
    }
  }
POLICY_RULE
}

/// output
output "aum_policy_set_prereq_for_updates_on_azure_vms_policy_definition_id" {
  value = azurerm_policy_definition.aum_policy_set_prereq_for_updates_on_azure_vms.id
}