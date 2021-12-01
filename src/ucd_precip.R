# GET UCD CLIMATE 

# pull data from UC Davis site:
# climate data from UC Climate (http://ipm.ucanr.edu/WEATHER/index.html)
# http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=&STN=DAVIS.T
# Archived Data: http://apps.atm.ucdavis.edu/wxdata/data/
# crosswalk: http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(lubridate) 
library(stringr)
library(glue)
library(janitor)
library(purrr)
library(glue)

# Download Data ----------------------------------------------------------------

# source functions
source("code/functions/f_download_davis_clim.R")
source("code/functions/f_get_sensor_metadata_davis_clim.R")
# download all data:
# f_download_dav_weather()
# download metadata
# f_get_sensor_metadata_davis_clim()

# get metadata
metadat <- read_csv("data_raw/sensor_info_by_id.csv")
(filenames <- metadat$metric_id)
# stations: 
# 1 | Russell Ranch  ("RR")
# 2 | Campbell Tract ("CT")
(filenames_ct <- filenames[grepl("^CT", filenames)])

# Import Data ------------------------------------------------------

# get data
alldat <- map(filenames_ct, ~read_csv(glue("data_raw/{.x}.csv.zip"), 
                            col_names = c("station_id", "sensor_id",
                                          "datetime", "value"), 
                            id = "filename")) %>% 
  bind_rows

# join by sensor id
alldat <- left_join(alldat, metadat)

# Get Summarized Data -----------------------------------------------------

# get historical climate data: daily
dav1980 <- read_csv("data_raw/climate_Davis_historical_1980_2021.csv", skip = 63) %>%
  clean_names() %>% 
  remove_empty() %>% 
  # select cols
  select(station:precip, air_max, air_min=min_7, evap, solar) %>% 
  # drop one NA
  filter(!is.na(date))

summary(dav1980)


# Clean Data --------------------------------------------------------------

# need to clean and fix time & date
dav <- dav1980 %>% 
  mutate(time = ifelse(nchar(time) < 4, str_pad(time, side = "left", width = 4, pad="0"),  time),
         datetime = ymd_hm(paste0(as.character(date), time)), .after=date,
         M = month(datetime))

# add DOY
dav <- dav %>% wateRshedTools::add_WYD("datetime")

# add decade
dav$decade <- cut(x = dav$WY, 
                  include.lowest = T, dig.lab = 4, 
                  breaks = c(1969, 1979, 1989, 1999, 2009, 2019),
                  labels = c('1970s', '1980s','1990s','2000s','2010s'))

# clean 
dav_feb <- dav %>% 
  filter(M==2) %>% # limit to FEB 
  group_by(WY, M) %>% 
  summarize("totPPT_mm"=sum(precip),
            "avgPPT_mm"=mean(precip),
            "maxPPT_mm"=max(precip),
            "minPPT_mm"=min(precip),
            "avgAir_max"=mean(air_max),
            "maxAir_max"=max(air_max),
            "avgAir_min"=mean(air_min),
            "minAir_min"=min(air_min))

# add decade
dav_feb$decade <- cut(x = dav_feb$WY, 
                  include.lowest = T, dig.lab = 4, 
                  breaks = c(1969, 1979, 1989, 1999, 2009, 2019),
                  labels = c('1970s', '1980s','1990s','2000s','2010s'))


# Plot Feb Precip -------------------------------------------------------------

# precip in FEB
ggplot() +
  geom_crossbar(data=dav_feb, aes(x=WY, y=avgPPT_mm, ymax=maxPPT_mm, ymin=minPPT_mm, group=WY), alpha= 0.5, fill="cyan4") +
  theme_bw()
  #facet_grid(M~.)

# precip plot
ggplot(data = dav_feb, aes(x = as.factor(WY), y = totPPT_mm, group=WY)) +
  geom_point(data=dav_feb[dav_feb$WY==2016,], aes(x=as.factor(WY), y=totPPT_mm, group=WY), color="maroon", alpha=0.8) +
  geom_smooth(data=dav_feb, aes(x=as.factor(WY), y= totPPT_mm, group=M), alpha=0.3) +
  geom_point(data=dav_feb, aes(x=as.factor(WY),y=totPPT_mm, group=WY), color="gray20", size=2.7)+
  geom_point(data=dav_feb[dav_feb$WY==2016,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==1983,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==1998,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==2017,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==1988,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==1992,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==2003,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==2019,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
  geom_point(data=dav_feb[dav_feb$WY==2010,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
  geom_text(data=dav_feb[dav_feb$WY==2019 |dav_feb$WY==2016 | dav_feb$WY==1983 | dav_feb$WY==1988 | dav_feb$WY==1998 | dav_feb$WY==1992 | dav_feb$WY==2003 | dav_feb$WY==2010 | dav_feb$WY==2017,], 
             aes(label=WY, x=as.factor(WY), y=totPPT_mm), size=3, vjust = -0.90, nudge_y=-0.5, fontface = "bold")+
  ylab(paste("Total Precipitation (mm)")) + theme_bw() + xlab("") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  labs(title = "February Precip (mm) in Davis: 1971-2020",
       caption = "Data Source: http://atm.ucdavis.edu/weather/")

# ggsave(filename = "figs/Feb_ppt_Davis_1971-2020.png", width = 8, height=5, units = "in", dpi = 300)


# Plot Feb Airtemp --------------------------------------------------------

# airtemp in FEB
ggplot() +
  geom_point(data=dav_feb, aes(x=WY, y=avgAir_max, group=WY), color="maroon", alpha=0.8) +
  geom_ribbon(data=dav_feb, aes(x=WY, ymax=avgAir_max, ymin=avgAir_min, group=WY), color="gray20", alpha=0.7)+
  geom_smooth(data=dav_feb, aes(x=WY, y= avgAir_max)) +
  ylim(c(50,70))+
  #theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
  labs(title = "February Air Temperature in Davis: 1981-2021", caption="Data Source: http://atm.ucdavis.edu/weather/", 
       x="", y=expression(paste("Air Temp (", degree, "C)")))+
  theme_bw()

ggsave(filename = "figs/Feb_airtemp_Davis_1981-2021.png", width = 8, height=6, units = "in", dpi = 300)

# do some stats by decade to look for changes in ppt
library(coin) 

# monte carlo sampling of precip vs decade using FEB only
oneway_test(totPPT_mm ~ decade,
            data=dav_feb, 
            distribution='approximate')

# monte carlo sampling of avgAir_max vs decade using FEB only
oneway_test(avgAir_max ~ decade, 
            data=dav_feb, 
            distribution='approximate')

