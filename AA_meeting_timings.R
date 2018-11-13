###################################################################
# Explore patterns in timings of Alcohol Anonymous meetings       #
# including day of week, time of day and duration                 #
#                                                                 #
# Date: October 2018                                              #
# Author: Gaskyk                                                  #
###################################################################


## Import libraries
library(tidyverse)
library(chron)


############# Time of day

# Read in data which has time of day
aa_meetings_time <- read.csv("xx/aa_meetings_formatted.csv",
                        stringsAsFactors = FALSE)

# Format times to time format
aa_meetings_time$times <- times(aa_meetings_time$times)

# Histogram of times of meetings
qplot(times, data=aa_meetings_time, bins=24) + labs(x="Times (24 hour clock)", y="Count",
                                               title="AA meeting start times") +
  theme(plot.title = element_text(hjust = 0.5))

# Summarise meeting times
times_summary <- data.frame(table(aa_meetings_time$times))

# Early and late starts (select the 6am and 10.30pm starts)
early_late_starts <- aa_meetings_time %>%
  filter((times==6) | (times==22.3))


############# Day of week

# Read in data which has day of week
aa_meetings_day <- read.csv("xx/aa_meetings.csv",
                        stringsAsFactors = FALSE)
aa_meetings_day$X <- NULL
colnames(aa_meetings_day)[1] <- "text"

# Add a field which extracts day of week from text
aa_meetings_day$day_of_week <- NA
for (day in c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
  {aa_meetings_day$day_of_week <- ifelse(is.na(aa_meetings_day$day_of_week),
                                      ifelse(grepl(day, aa_meetings_day$text), day, NA),
                                      aa_meetings_day$day_of_week)}

# Histogram of days of meetings, first excluding missing data
days <- aa_meetings_day %>%
    filter(!is.na(aa_meetings_day$day_of_week))
qplot(day_of_week, data=days) + labs(x="Day of week", y="Count", title="AA meeting days") +
  theme(plot.title = element_text(hjust = 0.5))

# Summarise meeting days
days_summary <- data.frame(table(days$day_of_week))


############# Duration

# Look at hours
aa_meetings_day$duration_hours <- NA
for (i in 1:3)
  {hours <- paste(i, "hr", sep = "")
  aa_meetings_day$duration_hours <- ifelse(is.na(aa_meetings_day$duration_hours),
                                           ifelse(grepl(hours, aa_meetings_day$text), hours, NA),
                                           aa_meetings_day$duration_hours)}

# Look at minutes
aa_meetings_day$duration_mins <- NA
for (i in c("05", 10, 15, 20, 25, 30, 35, 40, 45, 50, 55))
  {minutes <- paste(i, "mins", sep = "")
  aa_meetings_day$duration_mins <- ifelse(is.na(aa_meetings_day$duration_mins),
                                         ifelse(grepl(minutes, aa_meetings_day$text), minutes, NA),
                                         aa_meetings_day$duration_mins)}

# Where meetings are whole hours in length, fill missing in minutes column
aa_meetings_day$duration_mins <- ifelse((is.na(aa_meetings_day$duration_mins)) &
                                          (!is.na(aa_meetings_day$duration_hours)),
                                        "00mins", aa_meetings_day$duration_mins)

# Calculate total duration in hours and minutes
aa_meetings_day$duration <- ifelse((!is.na(aa_meetings_day$duration_hours)),
                                   paste(aa_meetings_day$duration_hours, ":", 
                                   aa_meetings_day$duration_mins, sep=""), NA)

# Remove hours and mins
aa_meetings_day$duration <- gsub("hr", "", aa_meetings_day$duration)
aa_meetings_day$duration <- gsub("mins", "", aa_meetings_day$duration)

# Histogram of durations of meetings, first excluding missing data
durations <- aa_meetings_day %>%
  filter(!is.na(aa_meetings_day$duration))
qplot(duration, data=durations) + labs(x="Length of meeting", y="Count", title="AA meeting durations") +
  theme(plot.title = element_text(hjust = 0.5))

# Summarise meeting days
durations_summary <- data.frame(table(durations$duration))

