# download Davis climate data

library(optparse)
source("code/functions/f_download_davis_clim.R")

f_download_dav_clim(unlist(snakemake@input[["outdir"]]))
print("Done!")
