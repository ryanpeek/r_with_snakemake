# download Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)
library(fs)


#print(snakemake@input[[1]]) # prints dir and file!
print(snakemake@output[["csv"]]) # prints dir and file!

# Get outdir only (not full path)
#outdir <- fs::path_dir(snakemake@output[["csv"]])
outdir <- "data_raw"

# check/create dir exists
fs::dir_create(glue("{outdir}"))

# get metadata
#metadat <- read_csv(glue("{outdir}/davis_sensor_info_by_id.csv"), )

# print message:
print("Getting metadata")
# get metadata
metadat <- read_delim("http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt",
                      trim_ws = TRUE,
                      delim="|", skip = 3,
                      col_names = c("x1", "sensor_id", "metric_id",
                                    "station_id", "metric_name",
                                    "metric_units", "x2")) %>%
  select(-(starts_with("x"))) %>%
  filter(!is.na(sensor_id))

print("Saving metdata")
#write_csv(metadat, snakemake@output[['csv']])
write_csv(metadat, glue("{outdir}/davis_sensor_info_by_id.csv"))
# pull filenames from metadat
filenames <- metadat$metric_id

# get only stations that start with CT cambell tract
filenames_ct <- filenames[grepl("^CT", filenames)]
# stations:
# 1 | Russell Ranch  ("RR")
# 2 | Campbell Tract ("CT")

# download_files
map(filenames_ct,
    ~download.file(
      url = glue("http://apps.atm.ucdavis.edu/wxdata/data/{.x}.zip"),
      destfile = glue("{outdir}/{.x}.csv.zip")))
print("Done!")

