# download Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)

f_download_dav_clim <- function(outdir="data_raw"){
  #outdir <- snakemake@wildcards[["outdir"]]
  # get metadata
    metadat <- read_delim("http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt", trim_ws = TRUE,
                        delim="|", skip = 3,
                        col_names = c("x1", "sensor_id", "metric_id",
                                      "station_id", "metric_name",
                                      "metric_units", "x2")) %>% 
    select(-(starts_with("x"))) %>% 
    filter(!is.na(sensor_id))
  
  # pull filenames from metadat
  filenames <- metadat$metric_id
  # get only stations that start with CT cambell tract
  filenames_ct <- filenames[grepl("^CT", filenames)]
  # stations: 
  # 1 | Russell Ranch  ("RR")
  # 2 | Campbell Tract ("CT")
  
  # check/create dir exists
  fs::dir_create(glue("{outdir}"))
  
  # download_files
  map(filenames_ct, 
      ~download.file(
        url = glue("http://apps.atm.ucdavis.edu/wxdata/data/{.x}.zip"), 
        destfile = glue("{outdir}/{.x}.csv.zip")))
  print("Done!")
}
  


# run with: 
#f_download_dav_clim("data_raw")
