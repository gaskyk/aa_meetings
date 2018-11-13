# AA meetings

## Overview

Web scrape and analyse information about Alcoholics Anonymous meetings in Great Britain:
- Web scrape information from the [Alcoholics Anonymous website](https://www.alcoholics-anonymous.org.uk/aa-meetings/Find-a-Meeting)
- Understand whether the location of meetings correlates with other public health indicators of alcohol use
- Produce a chloropleth map showing meeting density
- Analyse meeting by day of week, time of day and duration

## How do I use this project?

### Run Python then R files

Take care to edit the file paths in each file

Web scraping is done first using Python 3.6 in the file *aa_web_scrape.py*. Packages required:
- bs4
- urllib
- selenium
- time
- pandas

Analysis and graphs are done after running the above code using R 3.4.3. Libraries required:
- chron
- tidyverse
- fingertipsR
- reshape2

For the mapping in R, the following libraries are required:
- maptools
- leaflet
- htmltools
