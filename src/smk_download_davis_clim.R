# download Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)
library(fs)
#library(optparse)

# add some error and CLI parsing
# option_list <- list(
#   make_option(c("-o", "--outdir"),
#               type = "character",
#               default = "data_raw",
#               help = "a dir name",
#               metavar = "character")
# )
# 
# opt_parser <- OptionParser(option_list = option_list);
# opt <- parse_args(opt_parser);

# if (is.null(opt$outdir)){
#   print_help(opt_parser)
#   stop("outdir must be provided", call. = FALSE)
# }

print(snakemake@input[[1]]) # prints dir and file!

# Get outdir only (not full path)
outdir <- fs::path_dir(snakemake@input[[1]])

# get metadata
metadat <- read_csv(glue("{outdir}/davis_sensor_info_by_id.csv"), )
#metadat <- read_csv(glue("{opt$outdir}/davis_sensor_info_by_id.csv"), )

# pull filenames from metadat
filenames <- metadat$metric_id
# get only stations that start with CT cambell tract
filenames_ct <- filenames[grepl("^CT", filenames)]
# stations:
# 1 | Russell Ranch  ("RR")
# 2 | Campbell Tract ("CT")

# check/create dir exists
#fs::dir_create(glue("{opt$outdir}"))
fs::dir_create(glue("{outdir}"))

# download_files
map(filenames_ct,
    ~download.file(
      url = glue("http://apps.atm.ucdavis.edu/wxdata/data/{.x}.zip"),
      destfile = glue("{outdir}/{.x}.csv.zip")))
print("Done!")

