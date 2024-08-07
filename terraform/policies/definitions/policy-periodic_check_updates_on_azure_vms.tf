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
resource "azurerm_policy_definition" "aum_policy_periodic_check_updates_on_azure_vms" {
  name         = "${var.deploymentEnvironment}-aum-policy-periodic_check_updates_on_azure_vms"
  display_name = "Configure periodic checking for missing system updates on azure virtual machines"
  description  = "Configure auto-assessment (every 24 hours) for OS updates on native Azure virtual machines. You can control the scope of assignment according to machine subscription, resource group, location or tag. Learn more about this for Windows: https://aka.ms/computevm-windowspatchassessmentmode, for Linux: https://aka.ms/computevm-linuxpatchassessmentmode."
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
    "assessmentMode": {
      "type": "String",
      "metadata": {
        "displayName": "Assessment mode",
        "description": "Assessment mode for the machines."
      },
      "allowedValues": [
        "ImageDefault",
        "AutomaticByPlatform"
      ],
      "defaultValue": "AutomaticByPlatform"
    },
    "osType": {
      "type": "String",
      "metadata": {
        "displayName": "OS type",
        "description": "OS type for the machines."
      },
      "allowedValues": [
        "Windows",
        "Linux"
      ],
      "defaultValue": "Windows"
    },
    "locations": {
      "type": "Array",
      "metadata": {
        "displayName": "Machines locations",
        "description": "The list of locations from which machines need to be targeted.",
        "strongType": "location"
      },
      "defaultValue": []
    },
    "tagValues": {
      "type": "Object",
      "metadata": {
        "displayName": "Tags on machines",
        "description": "The list of tags that need to matched for getting target machines."
      },
      "defaultValue": {}
    },
    "tagOperator": {
      "type": "String",
      "metadata": {
        "displayName": "Tag operator",
        "description": "Matching condition for resource tags"
      },
      "allowedValues": [
        "All",
        "Any"
      ],
      "defaultValue": "Any"
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
          "field": "[if(equals(tolower(parameters('osType')), 'windows'), 'Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration.patchSettings.assessmentMode', 'Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.patchSettings.assessmentMode')]",
          "notEquals": "[parameters('assessmentMode')]"
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
                  "value": "[parameters('tagOperator')]",
                  "equals": "Any"
                },
                {
                  "value": "[greaterOrEquals(if(empty(field('tags')), 0, length(intersection(parameters('tagValues'), field('tags')))), 1)]",
                  "equals": true
                }
              ]
            },
            {
              "allOf": [
                {
                  "value": "[parameters('tagOperator')]",
                  "equals": "All"
                },
                {
                  "value": "[equals(if(empty(field('tags')), 0, length(intersection(parameters('tagValues'), field('tags')))), length(parameters('tagValues')))]",
                  "equals": true
                }
              ]
            }
          ]
        },
        {
          "anyOf": [
            {
              "allOf": [
                {
                  "anyOf": [
                    {
                      "field": "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration",
                      "exists": "true"
                    },
                    {
                      "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
                      "like": "Linux*"
                    }
                  ]
                },
                {
                  "value": "[parameters('osType')]",
                  "equals": "Linux"
                },
                {
                  "anyOf": [
                    {
                      "allOf": [
                        {
                          "anyOf": [
                            {
                              "value": "[field('Microsoft.Compute/imageId')]",
                              "contains": "Microsoft.Compute/galleries"
                            },
                            {
                              "value": "[field('Microsoft.Compute/imageId')]",
                              "contains": "Microsoft.Compute/images"
                            }
                          ]
                        },
                        {
                          "field": "Microsoft.Compute/virtualMachines/osProfile.computerName",
                          "exists": "true"
                        }
                      ]
                    },
                    {
                      "allOf": [
                        {
                          "anyOf": [
                            {
                              "field": "Microsoft.Compute/imageId",
                              "contains": "Microsoft.Compute/galleries"
                            },
                            {
                              "field": "Microsoft.Compute/imageId",
                              "contains": "Microsoft.Compute/images"
                            },
                            {
                              "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.createOption",
                              "equals": "Attach"
                            }
                          ]
                        },
                        {
                          "field": "Microsoft.Compute/virtualMachines/osProfile.computerName",
                          "exists": "false"
                        },
                        {
                          "value": "[requestContext().apiVersion]",
                          "greaterOrEquals": "2023-07-01"
                        }
                      ]
                    },
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
                    }
                  ]
                }
              ]
            },
            {
              "allOf": [
                {
                  "anyOf": [
                    {
                      "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration",
                      "exists": "true"
                    },
                    {
                      "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
                      "like": "Windows*"
                    }
                  ]
                },
                {
                  "value": "[parameters('osType')]",
                  "equals": "Windows"
                },
                {
                  "anyOf": [
                    {
                      "allOf": [
                        {
                          "anyOf": [
                            {
                              "value": "[field('Microsoft.Compute/imageId')]",
                              "contains": "Microsoft.Compute/galleries"
                            },
                            {
                              "value": "[field('Microsoft.Compute/imageId')]",
                              "contains": "Microsoft.Compute/images"
                            }
                          ]
                        },
                        {
                          "field": "Microsoft.Compute/virtualMachines/osProfile.computerName",
                          "exists": "true"
                        }
                      ]
                    },
                    {
                      "allOf": [
                        {
                          "anyOf": [
                            {
                              "field": "Microsoft.Compute/imageId",
                              "contains": "Microsoft.Compute/galleries"
                            },
                            {
                              "field": "Microsoft.Compute/imageId",
                              "contains": "Microsoft.Compute/images"
                            },
                            {
                              "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.createOption",
                              "equals": "Attach"
                            }
                          ]
                        },
                        {
                          "field": "Microsoft.Compute/virtualMachines/osProfile.computerName",
                          "exists": "false"
                        },
                        {
                          "value": "[requestContext().apiVersion]",
                          "greaterOrEquals": "2023-07-01"
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
                },
                {
                  "field": "Microsoft.Compute/imagePublisher",
                  "notEquals": "microsoft-ads"
                }
              ]
            }
          ]
        }
      ]
    },
    "then": {
      "effect": "modify",
      "details": {
        "roleDefinitionIds": [
          "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "conflictEffect": "audit",
        "operations": [
          {
            "condition": "[equals(tolower(parameters('osType')), 'windows')]",
            "operation": "addOrReplace",
            "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration.patchSettings.assessmentMode",
            "value": "[parameters('assessmentMode')]"
          },
          {
            "condition": "[equals(tolower(parameters('osType')), 'linux')]",
            "operation": "addOrReplace",
            "field": "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.patchSettings.assessmentMode",
            "value": "[parameters('assessmentMode')]"
          }
        ]
      }
    }
  }
POLICY_RULE
}

/// output
output "aum_policy_periodic_check_updates_on_azure_vms_policy_definition_id" {
  value = azurerm_policy_definition.aum_policy_periodic_check_updates_on_azure_vms.id
}