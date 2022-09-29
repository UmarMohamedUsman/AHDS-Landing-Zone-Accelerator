param subnetId string
param vmSize string
param location string = resourceGroup().location

@secure()
param secrets object

module keyvault '../keyvault/keyvault.bicep' = {
  name: 'keyvault-VM'
  params: {
    nameSufix: 'jumpbox'
    location: location
    secrets: secrets
  }
}

module jbnic '../vnet/nic.bicep' = {
  name: 'jbnic'
  params: {
    location: location
    subnetId: subnetId
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'jumpbox'
  location: location
  properties: {
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: secrets.user.value
      adminPassword: secrets.password.value
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-21h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jbnic.outputs.nicId
        }
      ]
    }
  }
}

// resource vmext 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
//   name: '${jumpbox.name}/csscript'
//   location: resourceGroup().location
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {}
//     protectedSettings: {
//       script: script64
//     }
//   }
// }
