import azure.cosmos.documents as documents
import azure.cosmos.cosmos_client as cosmos_client
from azure.cosmos.aio import CosmosClient
import azure.cosmos.exceptions as exceptions
from azure.cosmos.partition_key import PartitionKey
import json
import asyncio

import config

HOST = config.settings['host']
MASTER_KEY = config.settings['master_key']
DATABASE_ID = config.settings['database_id']
CONTAINER_ID = config.settings['container_id']

async def getItem(id):
  async with CosmosClient(HOST, {'masterKey': MASTER_KEY}) as client:
    db = client.get_database_client(DATABASE_ID)
    container = db.get_container_client(CONTAINER_ID)
    return await container.read_item(id, partition_key=id)

async def itemQuery(query):
  async with CosmosClient(HOST, {'masterKey': MASTER_KEY}) as client:
    db = client.get_database_client(DATABASE_ID)
    container = db.get_container_client(CONTAINER_ID)
    results = container.query_items(
        query="SELECT * FROM c WHERE c.CommonName LIKE @name OR c.ScientificName LIKE @name",
        parameters=[
            { "name":"@name", "value": "%" + query + "%"}
        ]
    )

    # iterates on "results" iterator to asynchronously create a complete list of the actual query results

    item_list = []
    async for item in results:
        item_list.append(item)

    # Asynchronously creates a complete list of the actual query results. This code performs the same action as the for-loop example above.
    item_list = [item async for item in results]
    return item_list

print(getItem("AGHE2"))