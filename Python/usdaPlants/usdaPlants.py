import csv, requests, json
from getDocxContent import *
import azure.cosmos.documents as documents
import azure.cosmos.cosmos_client as cosmos_client
import azure.cosmos.exceptions as exceptions
from azure.cosmos.partition_key import PartitionKey
import datetime

import config

# Cosmos API Settings

HOST = config.settings['host']
MASTER_KEY = config.settings['master_key']
DATABASE_ID = config.settings['database_id']
CONTAINER_ID = config.settings['container_id']

client = cosmos_client.CosmosClient(HOST, {'masterKey': MASTER_KEY})

db = client.get_database_client(DATABASE_ID)
container = db.get_container_client(CONTAINER_ID)

# Function for getting Plant Data

def getPlantData(s):
    url = "https://plantsservices.sc.egov.usda.gov/api/PlantProfile?symbol=" + s
    response = requests.get(url)
    response.raise_for_status()                                                             # Error reporting
    return json.loads(response.text)

# Function for getting .docx URL

def getDocxURL(p):
    docxUrl = False
    if p['PlantGuideUrls']:
        for j in range(len(p['PlantGuideUrls'])):
            if str(p['PlantGuideUrls'][j]).find(".docx") != -1:
                docxUrl = 'https://plants.usda.gov' + p['PlantGuideUrls'][j]
                break
    elif p['FactSheetUrls']:
        for j in range(len(p['FactSheetUrls'])):
            if str(p['FactSheetUrls'][j]).find(".docx") != -1:
                docxUrl = 'https://plants.usda.gov' + p['FactSheetUrls'][j]
                break
    return docxUrl

# 1. Imports CSV and converts it to array. 2. Opens CSV to be written to

plantList = open('usdaPlantsFacts.csv', encoding='utf-8-sig')
plantListReader = csv.reader(plantList)
plantListData = list(plantListReader)

# Loops through list grabbing each  plant symbol

for i in range(len(plantListData)):
    symbol = plantListData[i][0]

    try:
        container.read_item(symbol, symbol)
        recordExists = True
    except exceptions.CosmosResourceNotFoundError:
        recordExists = False

    if recordExists:
        print(f'{symbol} item already exists.')
    else:
        print(f'Creating item for {symbol}.')
        

        plantData = getPlantData(symbol)
        url = getDocxURL(plantData)
        print(url)
        
        plantData['Plant Facts'] = getDocxContent(url)
        plantData['id'] = plantData['Symbol']

        container.upsert_item(plantData)

    # pprint.pprint(jsonPlantData)