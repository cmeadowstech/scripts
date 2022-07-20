import requests, docx, io

def getDocxContent(u):
    facts = {
        'Adaptation' : '',
        'Description' : '',
        'Establishment' : '',
        'Environmental Concerns' : '',
        'Management' : '',
        'Pests and Potential Problems' : '',
        'Planting Guidelines' : '',
        'Uses' : ''
    }

    if u:
        file = requests.get(u, stream=True)
        doc = docx.Document(io.BytesIO(file.content))

        for i in range(len(doc.paragraphs)):
            if doc.paragraphs[i].text in facts.keys():
                try:
                    facts[doc.paragraphs[i].text] = doc.paragraphs[i+1].text
                except:
                    continue

            if str(doc.paragraphs[i].text).find(":") != -1:
                paragraph = str(doc.paragraphs[i].text).split(":", 1)
                if paragraph[0] in facts.keys():
                    facts[paragraph[0]] = str(paragraph[1]).lstrip()

    return facts

