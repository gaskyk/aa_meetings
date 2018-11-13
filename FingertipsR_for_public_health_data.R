#####################################################################
# Analyse whether alcohol indicators from Public Health England     #
# are correlated with location of Alcohol Anonymous meetings        #
#                                                                   #
# Date: October 2018                                                #
# Author: Gaskyk                                                    #
#####################################################################

## Import libraries
library(tidyverse)
library(fingertipsR)
library(reshape2)

############# Get alcohol indicators, filter for latest data and reformat

indicators <- indicators()

# Get any indicator related to alcohol
alcohol_indicators <- indicators %>%
  filter(str_detect(IndicatorName, regex('alcohol', ignore_Case = T))) %>%
  distinct(IndicatorID, .keep_all = TRUE)

alcohol_indicators_vector <- alcohol_indicators[['IndicatorID']]

# Other options to include in fingertips_data
# https://www.rdocumentation.org/packages/fingertipsR/versions/0.1.3/topics/fingertips_data

# Query the data
# This calls the API for all alcohol-related indicators at county and UA level
# Counties and unitary authorities have AreaID 102
query <- fingertips_data(IndicatorID = alcohol_indicators_vector, AreaTypeID = 102)

# Remove country and region data. Now 152 distinct areas and 38 distinct IndicatorIDs
filtered_data <- query %>%
  filter(AreaType == 'County & UA') %>%
  filter(Sex == 'Persons')

# Also filter for the latest year of data as many indicators have data for multiple years
filtered_data <- filtered_data %>%
  filter((IndicatorID == 93012 & Timeperiod == "2014/15 - 16/17")|
           (IndicatorID == 93011 & Timeperiod == "2016/17")|
           (IndicatorID == 91455)|
           (IndicatorID == 91793)|
           (IndicatorID == 90836)|
           (IndicatorID == 91385 & Timeperiod == "2014/15")|
           (IndicatorID == 92778)|
           (IndicatorID == 92774)|
           (IndicatorID == 92770)|
           (IndicatorID == 92768)|
           (IndicatorID == 92765)|
           (IndicatorID == 92763)|
           (IndicatorID == 91463 & Timeperiod == "2016")|
           (IndicatorID == 91418 & Timeperiod == "2016/17")|
           (IndicatorID == 91417 & Timeperiod == "2016/17")|
           (IndicatorID == 91413 & Timeperiod == "2016/17")|
           (IndicatorID == 91412 & Timeperiod == "2016/17")|
           (IndicatorID == 91411 & Timeperiod == "2016/17")|
           (IndicatorID == 92321 & Timeperiod == "2016/17")|
           (IndicatorID == 92316 & Timeperiod == "2016/17")|
           (IndicatorID == 92712 & Timeperiod == "2016")|
           (IndicatorID == 91409 & Timeperiod == "2016/17")|
           (IndicatorID == 92320 & Timeperiod == "2016/17")|
           (IndicatorID == 91382 & Timeperiod == "2016")|
           (IndicatorID == 91295 & Timeperiod == "2016/17")|
           (IndicatorID == 91182 & Timeperiod == "2016/17")|
           (IndicatorID == 91416 & Timeperiod == "2016/17")|
           (IndicatorID == 91123 & Timeperiod == "2016/17")|
           (IndicatorID == 93193)|
           (IndicatorID == 92455 & Timeperiod == "2014/15")|
           (IndicatorID == 92906 & Timeperiod == "2016/17")|
           (IndicatorID == 90931 & Timeperiod == "2012/13 - 14/15")|
           (IndicatorID == 90929 & Timeperiod == "2016/17")|
           (IndicatorID == 90875 & Timeperiod == "2014 - 16")|
           (IndicatorID == 90861 & Timeperiod == "2014 - 16")|
           (IndicatorID == 92904 & Timeperiod == "2014/15 - 16/17")|
           (IndicatorID == 92447 & Timeperiod == "2016")|
           (IndicatorID == 91414 & Timeperiod == "2016/17"))

# Long to wide format
final_phe_data <- dcast(filtered_data, AreaCode ~ IndicatorID, value.var="Value")

# Also summarise the metadata
metadata <- filtered_data %>%
  distinct(IndicatorID, IndicatorName, Sex, Age, Timeperiod)


############# Get total residential population data for England and Wales in 2016

# Population by five year age group and sex for local authorities and counties in England
# Then filter for all persons for 2016 and keep only selected columns
eng_pop <- fingertips_data(IndicatorID = 92708, AreaTypeID = 102)
eng_pop <- eng_pop %>%
  filter(Sex=="Persons" & Age=="All ages" & AreaType=="County & UA" & Timeperiod=="2016") %>%
  select(AreaCode, AreaName, Value)
colnames(eng_pop)[3] <- "population"

# Bring in Welsh and Scottish population (as Public Health England fingertips data only covers England)
ws_pop <- read.csv("xx/Welsh_Scottish_popn.csv",
                          stringsAsFactors = FALSE)

# Welsh and English population
ews_pop <- rbind(eng_pop, ws_pop)


############# Get Alcohol Anonymous meetings location and calculate meetings per 100,000
############# population in England and Wales

# Read in AA meetings data
aa_meetings <- read.csv("xx/aa_meetings_formatted.csv",
                   stringsAsFactors = FALSE)

# Read in lookup of local authority / county in England
# http://geoportal.statistics.gov.uk/datasets/local-authority-district-to-county-december-2017-lookup-in-england
la_county_lookup <- read.csv("xx/Local_Authority_District_to_County_December_2017_Lookup_in_England.csv",
                             stringsAsFactors = FALSE)

# Merge aa_meetings and la_county_lookup
aa_meetings <- merge(aa_meetings, la_county_lookup, by.x = "laua", by.y = "LAD17CD", all.x = TRUE)
# Create new local authority / county field
aa_meetings$la_county <- ifelse(!is.na(aa_meetings$CTY17CD), aa_meetings$CTY17CD, aa_meetings$laua)

# Count number of meetings per local authority in Great Britain
meeting_count <- aa_meetings %>%
  count(la_county)
colnames(meeting_count)[2] <- "aa_meeting_count"

# Merge with population data
meeting_count <- merge(ews_pop, meeting_count, by.x = "AreaCode", by.y = "la_county", all.x = TRUE)

# Calculate meetings per 100,000 population
meeting_count$meetings_per_pop = round(meeting_count$aa_meeting_count / meeting_count$population *100000, digits=1)

# Save total population to CSV
write.table(meeting_count, file="xx/aa_meetings_per_pop.csv",
            sep = ",", col.names = TRUE, row.names = FALSE, append = FALSE)


############# Merge Alcohol Anonymous meetings per 100,000 people with data from Public
############# Health England to understand if there are any correlations with alcohol
############# indicators

final_data <- merge(final_phe_data, meeting_count, by = "AreaCode")

# Correlate AA meetings in an area with other indicators
correlate <- list()
for (i in 2:39)
  {x <- cor(final_data[[i]], final_data$meetings_per_pop, use = "complete.obs")
  correlate <- append(correlate, x)}

correlate_df <- t(data.frame(correlate))
colnames(correlate_df)[1]<- "correlation"

correlate_df <- cbind(metadata, correlate_df)
row.names(correlate_df) <- 1:38
correlate_df <- correlate_df[order(correlate_df$correlation), ]

