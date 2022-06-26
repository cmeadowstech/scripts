## Python Scripts

### transmissionConvertCopy.py

My first "real" Python script. It's a script designed to work with the Transmission client. It automatically runs after completion, and checks if the subtitles are in a SRT format or not. If they're not, it will convert them. All files will then be copied over to the directory I have set up to use with Plex. Plex doesn't work well with subtitles in formats other than SRT, hence the need to convert them ussing FFMPEG.

Could probably be accomplished with bash in fewer lines, but you work with what you got. 

### usdaPlants

A fun, personal project designed to scrape data from the [USDA Plants Database](https://plants.usda.gov/home). Unfortunately the API they use for their website is limited to rather specific details, such as scientific names and ancestory. However, ~1100 plants have plant guides or fact sheets linked with more descriptive information.

Along with scraping the API for these select plants, it also takes those .docx documents and scrapes some information from them as well. Unfortunately these documents are not all structured the same way or may not have the same information, but I think it grabs a pretty good bit of information.

All this data is then sent up to a Cosmos DB which is configured for the Core(SQL) API. 

