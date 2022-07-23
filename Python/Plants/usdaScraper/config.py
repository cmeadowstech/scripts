import os

settings = {
    'host': os.environ.get('ACCOUNT_HOST', 'https://usda-plants-db.documents.azure.com:443/'),
    'master_key': os.environ.get('ACCOUNT_KEY', 'EbsY32MVuZasNVLH6BQDLIk6Eiftu5w6NZOcTUdjtTcs3GhVb60fz1IsI1WTXqZIBVTeF5JN1hpPsowwqBTTAg=='),
    'database_id': os.environ.get('COSMOS_DATABASE', 'usdaPlants'),
    'container_id': os.environ.get('COSMOS_CONTAINER', 'Items'),
}