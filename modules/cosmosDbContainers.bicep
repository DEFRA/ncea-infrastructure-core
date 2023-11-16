@description('Cosmos DB account name. The account where the collection will be created')
param databaseAccount string

@description('Cosmos Database name. The database where the collection will be created')
param databaseName string

@description('Cosmos Database name. The database where the collection will be created')
param collectionName string

@description('Partition Key. Key to be used for partitioning data into multiple partitions. Choose JSON property with wide range of values to distribute data evenly')
param partitionKey string

// Get existing cosmos account id
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' existing = {
  name: databaseAccount
}

// Get existing cosmos database id
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-09-15' = {
  name: databaseName
  parent: cosmosAccount
  properties: {
    options: {}
    resource: {
      id: databaseName
    }
  }
}

resource cosmosCollection 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-09-15' = {
  parent: cosmosDatabase
  name: collectionName
  properties: {
    resource: {
      id: collectionName
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          partitionKey
        ]
        kind: 'Hash'
        version: 2
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}

output cosmosAccountId string = cosmosAccount.id
