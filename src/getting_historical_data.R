# GET historical data

# list of stations in Yolo County: http://ipm.ucanr.edu/calludt.cgi/WXPCLISTSTNS?MAP=&PATH=CNTY&COUNTY=YO&ACTIVE=1&NETWORK=&STN=

# while archived data is available here: http://apps.atm.ucdavis.edu/wxdata/data/, it does not go back beyond about 2009.

# To download data prior to ~2009 requires accessing a menu GUI page:

## DAVIS.C station (1951-current)
## http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=yolo.html&STN=DAVIS.C

## DAVIS.A station (1982-current)
## http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=yolo.html&STN=DAVIS.A

## DAVIS.T station (1981-current)
## http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=yolo.html&STN=DAVIS.T

# to find a crosswalk for identifying the sensor ID info:
## http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt

# Could only download in 20-30 yr increments and then pasted together to 
# create "davis_daily_historical_1908_2022.csv

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(lubridate) 
library(stringr)
library(glue)
library(janitor)
library(purrr)
library(glue)

# Download Data ----------------------------------------------------------------


# Get metadata --------------------

metadat <- read_csv("data_raw/davis_sensor_info_by_id.csv")
(filenames <- metadat$metric_id)

# stations: 
# 1 | Russell Ranch  ("RR")
# 2 | Campbell Tract ("CT")

# just precip
ppt_ct <- filenames[grepl("CT_Rain_Tot24", filenames)]
temp_ct <- filenames[grepl("CT_Ta2m", filenames)]

# bind
filenames_ct <- c(ppt_ct, temp_ct)

# Import Data ------------------------------------------------------

# get data
alldat <- map(filenames_ct, ~read_csv(glue("data_raw/zips/{.x}.csv.zip"), 
                            col_names = c("station_id", "sensor_id",
                                          "datetime", "value"), 
                            id = "filename")) %>% 
  bind_rows

# join by sensor id
alldat <- left_join(alldat, metadat)

# Get Summarized Data -----------------------------------------------------

# get historical climate data: daily DAVIS.A
# http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=yolo.html&STN=DAVIS.A

dav1980 <- read_csv("data_raw/davis_daily_historical_1980_2021.csv", skip = 63) %>%
  clean_names() %>% 
  remove_empty() %>% 
  # select cols
  select(station:precip, air_max, air_min=min_7, evap, solar) %>% 
  # drop one NA
  filter(!is.na(date)) %>% 
  # add date
  mutate(date = ymd(as.character(date)),
         M = month(date),
         air_max = air_max * 9/5 + 32,
         precip_in = precip * 0.0393701)

summary(dav1980)

dav1951 <- read_csv("data_raw/davis_daily_historical_1951_2022.csv", skip = 59) %>%
  clean_names() %>% 
  remove_empty() %>% 
  # select cols
  select(station:precip, air_max, air_min=min_7, evap, solar) %>% 
  # drop one NA
  filter(!is.na(date)) %>% 
  mutate(date = ymd(as.character(date)),
         M = month(date)) %>% 
  rename(precip_in = precip)

summary(dav1951)

# quick compare temp
ggplot() + geom_line(data=dav1951, aes(x=date, y=air_max), color="black") +
  geom_line(data=dav1980, aes(x=date, y=air_max), color="orange")

# quick compare precip
ggplot() + geom_line(data=dav1951, aes(x=date, y=precip_in), color="black") +
  geom_line(data=dav1980, aes(x=date, y=precip_in), color="orange")

