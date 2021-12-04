# download Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)
library(optparse)

# add some error and CLI parsing
option_list <- list(
  make_option(c("-o", "--outdir"),
              type = "character",
              default = "data_raw",
              help = "a dir name",
              metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list);
opt <- parse_args(opt_parser);

# if (is.null(opt$outdir)){
#   print_help(opt_parser)
#   stop("outdir must be provided", call. = FALSE)
# }

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
fs::dir_create(glue("{opt$outdir}"))

# download_files
map(filenames_ct, 
    ~download.file(
      url = glue("http://apps.atm.ucdavis.edu/wxdata/data/{.x}.zip"), 
      destfile = glue("{opt$outdir}/{.x}.csv.zip")))
print("Done!")

