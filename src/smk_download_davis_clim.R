# download Davis climate data

library(optparse)
source("src/f_download_davis_clim.R")

f_download_dav_clim(snakemake@wildcards[["outdir"]])
print("Done!")
