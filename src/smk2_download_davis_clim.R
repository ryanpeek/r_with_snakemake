# download Davis climate data:
# http://ipm.ucanr.edu/WEATHER/index.html
# see here for daily 1980 to current:
## http://ipm.ucanr.edu/calludt.cgi/WXSTATIONDATA?MAP=&STN=DAVIS.T


library(purrr)
library(dplyr)
library(glue)
library(readr)
library(fs)


print(snakemake@input[[1]]) # prints dir and file!
#print(snakemake@output[["csv"]]) # prints dir and file!

# Get outdir only (not full path)
outdir <- snakemake@output[[1]]
print(glue("Saving to {outdir}"))

# check/create dir exists
fs::dir_create(glue("{outdir}"))

# print message:
print("Getting metadata")

# get metadata
metadat <- read_csv(snakemake@input[[1]])

# # get metadata
# metadat <- read_delim("http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt",
#                       trim_ws = TRUE,
#                       delim="|", skip = 3,
#                       col_names = c("x1", "sensor_id", "metric_id",
#                                     "station_id", "metric_name",
#                                     "metric_units", "x2")) %>%
#   select(-(starts_with("x"))) %>%
#   filter(!is.na(sensor_id))

#write_csv(metadat, snakemake@output[['csv']])

# pull filenames from metadat
filenames <- metadat$metric_id

# stations:
# 1 | Russell Ranch  ("RR")
# 2 | Campbell Tract ("CT")

# get only stations that start with have CT cambell tract
filenames_ct <- filenames[grepl("^CT", filenames)]

# get only rain and temp data:
filenames_sel <- metadat %>% filter(metric_id %in% c("CT_Rain_Tot24", "CT_Ta2m")) %>% 
  pull(metric_id)
  

# download_files
map(filenames_sel,
    ~download.file(
      url = glue("http://apps.atm.ucdavis.edu/wxdata/data/{.x}.zip"),
      destfile = glue("{outdir}/{.x}.csv.zip")))
print("Done!")

