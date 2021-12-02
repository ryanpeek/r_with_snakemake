# get metadata for sensors

library(tidyverse)

# get metadata
metadat <- read_delim("http://apps.atm.ucdavis.edu/wxdata/metadata/sensor_info_by_id.txt",
                      trim_ws = TRUE,
                      delim="|", skip = 3,
                      col_names = c("x1", "sensor_id", "metric_id",
                                    "station_id", "metric_name",
                                    "metric_units", "x2")) %>% 
  select(-(starts_with("x"))) %>% 
  filter(!is.na(sensor_id))

# for testing via Rscript in shell
#dir.create("data_raw", showWarnings = FALSE)
#write_csv(metadat, "data_raw/davis_sensor_info_by_id.csv")
write_csv(metadat, snakemake@output[['csv']])
