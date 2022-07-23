import csv, requests, json, re
import mwclient
import pprint

from io import StringIO
from html.parser import HTMLParser

# HTML Parse

class MLStripper(HTMLParser):
    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs= True
        self.text = StringIO()
    def handle_data(self, d):
        self.text.write(d)
    def get_data(self):
        return self.text.getvalue()

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()

# Settings for mwclient

ua = 'Plant Scraper (https://github.com/cmeadowstech)'
site = mwclient.Site('beta.floranorthamerica.org', clients_useragent=ua, scheme='http')
query = "[[Taxon rank::species]]"
volumes = 10,12,17,19,2,20,21,22,23,24,25,26,27,28,3,4,5,6,7,8,9                        # List of volumes http://beta.semanticfna.org/w/index.php?title=Special%3ASearchByProperty&property=Volume&value=

# Opens CSV to be written to

fieldNames = ['printouts','fulltext','fullurl','namespace','exists','displaytitle']

data_file = open('floraList.csv', 'a')
csv_writer = csv.writer(data_file, lineterminator = '\n')

# Runs query for page

result = site.get('query', prop='revisions', titles='Ammannia auriculata', rvslots='*', rvprop='content', formatversion=2)
content = result['query']['pages'][0]['revisions'][0]['slots']['main']['content']
content = content.split('|')
contentDict = {}

for c in content:
    if c.find('<span class="statement"') != -1:
        c = re.sub('.*\n?.*}}|{{.*\n?.*', '', strip_tags(c))
        contentDict['statement'] = c
        continue
    if c.find('=') != -1:
        c = c.split('=')
        contentDict[c[0]] = re.sub('.*\n?.*}}|{{.*\n?.*|\n', '', strip_tags(c[1]))

pprint.pprint(contentDict)

data_file.close()