import csv, requests, json
import mwclient

ua = 'Plant Scraper (https://github.com/cmeadowstech)'
site = mwclient.Site('beta.floranorthamerica.org', clients_useragent=ua, scheme='http')
query = "[[Taxon rank::species]]"
volumes = 10,12,17,19,2,20,21,22,23,24,25,26,27,28,3,4,5,6,7,8,9                        # List of volumes http://beta.semanticfna.org/w/index.php?title=Special%3ASearchByProperty&property=Volume&value=

# Opens CSV to be written to

fieldNames = ['printouts','fulltext','fullurl','namespace','exists','displaytitle']

data_file = open('floraList.csv', 'a')
csv_writer = csv.writer(data_file, lineterminator = '\n')

# Runs query on each volume

for volume in volumes:
    query = "[[Taxon rank::species]]" + f"[[Volume::Volume {str(volume)}]]"
    for answer in site.ask(query):
        print('Adding to CSV:',answer['displaytitle'])
        csv_writer.writerow(answer.values())

data_file.close()