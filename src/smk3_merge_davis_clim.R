# merge Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)
library(lubridate)
library(fs)
# #add some error and CLI parsing
# option_list <- list(
#   make_option(c("-i", "--input"),
#               type = "character",
#               default = "data_raw",
#               help = "a file name",
#               metavar = "character"),
#   make_option(c("-o", "--outdir"),
#               type = "character",
#               default = NULL,
#               help = "a dir name",
#               metavar = "character")
# )
# 
# opt_parser <- OptionParser(option_list = option_list);
# opt <- parse_args(opt_parser);
# 
# if (is.null(opt$outdir)){
#    print_help(opt_parser)
#    stop("outdir must be provided", call. = FALSE)
# }

# testing
#glue("{opt$input}") # this works only with rule shell:
#print(snakemake@params[[1]]) # this works only with rule script:

# indir <- "data_raw/zips"
# outdir <- "data_clean"

indir <- snakemake@params[["indir"]]
outdir <- snakemake@params[["outdir"]]

# check/create dir exists
glue("Create directory: {outdir}")
fs::dir_create(glue("{outdir}"))

# READ IN METADATA
# metadat <- read_csv(glue("data_raw/davis_sensor_info_by_id.csv"))

print("getting metadata...")
metadat <- read_csv(file = snakemake@input["meta"]$meta)
filenames <- metadat$metric_id # pull filenames from metadat

# get filenames present
filenames_ct <- fs::dir_ls(glue("{indir}/"), glob ="*.csv.zip")

# read in the files and make hourly
df_all <- map(filenames_ct,
    ~read_csv(.x, col_names = c("station_id", "sensor_id",
                                "value", "datetime"),
              id = "filename", show_col_types = FALSE)) %>%
  bind_rows %>%
  # convert to hourly
  mutate(datetime_hr = floor_date(datetime, "hours")) %>% 
  group_by(filename, station_id, sensor_id, datetime_hr) %>% 
  summarize(value_hr = mean(value, na.rm = TRUE)) %>% 
  left_join(metadat)


glue("Write out file: {outdir}/davis_clim_data.csv.gz...")

# write out (csv.gz = 125MB, write_rds.xz=, rda.xz=29MB, fst=160MB)
write_csv(df_all, file = glue("{outdir}/davis_clim_data.csv.gz"))
