# download Davis climate data

source("src/f_download_davis_clim.R")

f_download_dav_clim()
#length(dir("data_raw", "*.zip"))
print("Done!")
