import csv
import requests
import json
import pprint
from getDocxContent import *

# Function for getting Plant Data

def getPlantData(s):
    url = "https://plantsservices.sc.egov.usda.gov/api/PlantProfile?symbol=" + s
    response = requests.get(url)
    response.raise_for_status()                                                             # Error reporting
    return json.loads(response.text)

# Function for getting .docx URL

def getDocxURL(p):
    if p['PlantGuideUrls']:
        for j in range(len(p['PlantGuideUrls'])):
            if str(p['PlantGuideUrls'][j]).find(".doc") != -1:
                url = 'https://plants.usda.gov' + p['PlantGuideUrls'][j]
                break
    else:
        for j in range(len(p['FactSheetUrls'])):
            if str(p['FactSheetUrls'][j]).find(".doc") != -1:
                url = 'https://plants.usda.gov' + p['FactSheetUrls'][j]
                break
    return url

# 1. Imports CSV and converts it to array. 2. Opens CSV to be written to

plantList = open('usdaPlantsFacts_5.csv', encoding='utf-8-sig')
plantListReader = csv.reader(plantList)
plantListData = list(plantListReader)

data_file = open('data_file.csv', 'a')
csv_writer = csv.writer(data_file, lineterminator = '\n')

# Loops through list grabbing each  plant symbol

for i in range(len(plantListData)):
    symbol = plantListData[i][0]
    plantData = getPlantData(symbol)
    
    url = getDocxURL(plantData)
    plantData['Plant Facts'] = getDocxContent(url)
   # print(url)
   # print(getDocxContent(url))

    if i == 0:
        csv_writer.writerow(plantData.keys())

    csv_writer.writerow(plantData.values())

data_file.close()

'''data_file = open('data_file.csv', 'w')
csv_writer = csv.writer(data_file, lineterminator = '\n')

header = plantData.keys()
csv_writer.writerow(header)
csv_writer.writerow(plantData.values())

data_file.close()'''

# print(getDocxContent('https://plants.usda.gov/DocumentLibrary/plantguide/doc/pg_abam.docx'))

