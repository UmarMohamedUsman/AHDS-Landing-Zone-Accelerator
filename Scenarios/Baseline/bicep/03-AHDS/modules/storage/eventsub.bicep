param storageAccountName string
param queueName string

// defining Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}


resource ndjsonSubscription 'Microsoft.EventGrid/eventSubscriptions@2022-06-15' = {
  name: 'ndjsoncreated'
  properties: {
    destination: {
      endpointType: 'StorageQueue'
      // For remaining properties, see EventSubscriptionDestination objects
      properties: {
        queueName: queueName
        resourceId: storageAccount.id
      }
    }
    filter: {
      advancedFilters: [
        {
          operatorType: 'StringIn'
          key: 'data.api'
          values: [
            'CopyBlob', 'PutBlob', 'PutBlockList', 'FlushWithClose'
          ]
          // For remaining properties, see AdvancedFilter objects
        }
      ]
      subjectBeginsWith: '/blobServices/default/containers/ndjson'
      subjectEndsWith: '.ndjson'
    }
  }
}
