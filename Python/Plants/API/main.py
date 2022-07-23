import string
from fastapi import FastAPI
import azure.cosmos.documents as documents
import azure.cosmos.cosmos_client as cosmos_client
import azure.cosmos.exceptions as exceptions
from azure.cosmos.partition_key import PartitionKey
import json

import config

# Cosmos API Settings

HOST = config.settings['host']
MASTER_KEY = config.settings['master_key']
DATABASE_ID = config.settings['database_id']
CONTAINER_ID = config.settings['container_id']

client = cosmos_client.CosmosClient(HOST, {'masterKey': MASTER_KEY})

db = client.get_database_client(DATABASE_ID)
container = db.get_container_client(CONTAINER_ID)

# API Stuff

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/plants/{id}")
async def read_item(id):
    item = container.read_item(id, partition_key=id)
    return item

@app.get("/plants/")
async def read_item(name : str):
    # enable_cross_partition_query should be set to True as the container is partitioned
    items = list(container.query_items(
        query="SELECT * FROM c WHERE c.CommonName LIKE @name OR c.ScientificName LIKE @name",
        parameters=[
            { "name":"@name", "value": "%" + name + "%"}
        ],
        enable_cross_partition_query=True
    ))

    return items