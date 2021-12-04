# download Davis climate data

library(purrr)
library(dplyr)
library(glue)
library(readr)
library(optparse)

# add some error and CLI parsing
option_list <- list(
  make_option(c("-i", "--input"),
              type = "character",
              default = "data_raw",
              help = "a dir name",
              metavar = "character"),
  make_option(c("-o", "--outdir"),
              type = "character",
              default = NULL,
              help = "a dir name",
              metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list);
opt <- parse_args(opt_parser);

if (is.null(opt$outdir)){
   print_help(opt_parser)
   stop("outdir must be provided", call. = FALSE)
}

metadat <- read_csv(glue("{opt$input}/davis_sensor_info_by_id.csv"))
# pull filenames from metadat
filenames <- metadat$metric_id
# get only stations that start with CT cambell tract
filenames_ct <- glue("{opt$input}/{filenames[grepl('^CT', filenames)]}.csv.zip")
#filenames_ct

# check/create dir exists
fs::dir_create(glue("{opt$outdir}"))

# download_files
df_all <- map(filenames_ct, 
    ~read_csv(.x, col_names = c("station_id", "sensor_id",
                                "value", "datetime"), 
              id = "filename")) %>% 
  bind_rows %>% 
  left_join(metadat)

# may not write out, just avg get data we need
# write out (csv.gz = 125MB, write_rds.xz=, rda.xz=29MB, fst=160MB)
write_csv(df_all, file = glue("{opt$outdir}/davis_clim_data.csv.gz"))

# works but takes FOREVER
#save(df_all, file = glue("{opt$outdir}/davis_clim_data.rda"), compress = "xz")
#write_rds(df_all, file = glue("data_clean/davis_clim_data.rds"), compress = "xz")

# Plotting ----------------------------------------------------------------

# # work in progress
# # add DOY
# dav <- dav %>% wateRshedTools::add_WYD("datetime")
# 
# # add decade
# dav$decade <- cut(x = dav$WY, 
#                   include.lowest = T, dig.lab = 4, 
#                   breaks = c(1969, 1979, 1989, 1999, 2009, 2019),
#                   labels = c('1970s', '1980s','1990s','2000s','2010s'))
# 
# # clean 
# dav_feb <- dav %>% 
#   filter(M==2) %>% # limit to FEB 
#   group_by(WY, M) %>% 
#   summarize("totPPT_mm"=sum(precip),
#             "avgPPT_mm"=mean(precip),
#             "maxPPT_mm"=max(precip),
#             "minPPT_mm"=min(precip),
#             "avgAir_max"=mean(air_max),
#             "maxAir_max"=max(air_max),
#             "avgAir_min"=mean(air_min),
#             "minAir_min"=min(air_min))
# 
# # add decade
# dav_feb$decade <- cut(x = dav_feb$WY, 
#                       include.lowest = T, dig.lab = 4, 
#                       breaks = c(1969, 1979, 1989, 1999, 2009, 2019),
#                       labels = c('1970s', '1980s','1990s','2000s','2010s'))
# 
# # Plot Feb Precip -------------------------------------------------------------
# 
# # precip in FEB
# ggplot() +
#   geom_crossbar(data=dav_feb, aes(x=WY, y=avgPPT_mm, ymax=maxPPT_mm, ymin=minPPT_mm, group=WY), alpha= 0.5, fill="cyan4") +
#   theme_bw()
# #facet_grid(M~.)
# 
# # precip plot
# ggplot(data = dav_feb, aes(x = as.factor(WY), y = totPPT_mm, group=WY)) +
#   geom_point(data=dav_feb[dav_feb$WY==2016,], aes(x=as.factor(WY), y=totPPT_mm, group=WY), color="maroon", alpha=0.8) +
#   geom_smooth(data=dav_feb, aes(x=as.factor(WY), y= totPPT_mm, group=M), alpha=0.3) +
#   geom_point(data=dav_feb, aes(x=as.factor(WY),y=totPPT_mm, group=WY), color="gray20", size=2.7)+
#   geom_point(data=dav_feb[dav_feb$WY==2016,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==1983,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==1998,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==2017,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==1988,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==1992,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==2003,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==2019,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="maroon", size=4) +
#   geom_point(data=dav_feb[dav_feb$WY==2010,], aes(x=as.factor(WY),y=totPPT_mm, group=WY), pch=21, fill="lightpink", size=4) +
#   geom_text(data=dav_feb[dav_feb$WY==2019 |dav_feb$WY==2016 | dav_feb$WY==1983 | dav_feb$WY==1988 | dav_feb$WY==1998 | dav_feb$WY==1992 | dav_feb$WY==2003 | dav_feb$WY==2010 | dav_feb$WY==2017,], 
#             aes(label=WY, x=as.factor(WY), y=totPPT_mm), size=3, vjust = -0.90, nudge_y=-0.5, fontface = "bold")+
#   ylab(paste("Total Precipitation (mm)")) + theme_bw() + xlab("") +
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
#   labs(title = "February Precip (mm) in Davis: 1971-2020",
#        caption = "Data Source: http://atm.ucdavis.edu/weather/")
# 
# # ggsave(filename = "figs/Feb_ppt_Davis_1971-2020.png", width = 8, height=5, units = "in", dpi = 300)
# 
# 
# # Plot Feb Airtemp --------------------------------------------------------
# 
# # airtemp in FEB
# ggplot() +
#   geom_point(data=dav_feb, aes(x=WY, y=avgAir_max, group=WY), color="maroon", alpha=0.8) +
#   geom_ribbon(data=dav_feb, aes(x=WY, ymax=avgAir_max, ymin=avgAir_min, group=WY), color="gray20", alpha=0.7)+
#   geom_smooth(data=dav_feb, aes(x=WY, y= avgAir_max)) +
#   ylim(c(50,70))+
#   #theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) + 
#   labs(title = "February Air Temperature in Davis: 1981-2021", caption="Data Source: http://atm.ucdavis.edu/weather/", 
#        x="", y=expression(paste("Air Temp (", degree, "C)")))+
#   theme_bw()
# 
# 
# 
# print("Done!")
