# download Davis climate data

library(purrr)
library(janitor)
library(dplyr)
library(glue)
library(readr)
library(lubridate)
library(ggplot2)
library(patchwork)
source("src/f_add_wyd.R")

# The Data ----------------------------------------------------------------

print(snakemake@input[[1]]) 
infile <- snakemake@input[[1]]

# for testing
#data <- read_csv(file = "data_clean/davis_clim_data.csv.gz")

# from snakemake
data <- read_csv(file = infile)

# hist data to to add compare
data_hist <- read_csv(file = "data_raw/davis_daily_historical_1951_2021.csv", skip = 59) |> 
  clean_names() |> 
  mutate(date = ymd(date),
         precip_mm = precip * 25.4) |> 
  rename(precip_in = precip, air_max_c = air_max, air_min_c=min_7,
         soil_max_c = soil_max, soil_min_c=min_15,
         solar_wsqm = solar) |> 
  select(station, date, precip_in, precip_mm, air_max_c:air_min_c, soil_max_c:soil_min_c, solar_wsqm)

# add Water Year
data_hist <- data_hist |> 
  add_WYD("date")

# Clean Data ----------------------------------------------------------------

data <- data |> add_WYD("datetime_hr") |> 
  mutate(date = as.Date(datetime_hr), .before = datetime_hr)

# Make Daily Precip ----------------------------------------------------------

# clean and summarize subdaily to daily
ppt_daily <- data  |>  filter(metric_id == "CT_Rain_Tot24") |> 
  group_by(date, station_id, metric_id, DOY, WY, DOWY) |> 
  summarise(tot_ppt_mm = max(value_hr, na.rm=TRUE), # take max of last 24 hrs
            tot_ppt_in = tot_ppt_mm * 0.0393701) |> 
  ungroup() |> 
  mutate(week = as.factor(week(date)),
         month = as.factor(month(date))) |> 
  # reorder weeks/months for Water Years
  mutate(month = forcats::lvls_reorder(month, c(10:12,1:9)),
         week = forcats::lvls_reorder(week, c(40:53, 1:39))) |> 
  # drop 2009 since it's incomplete
  filter(!WY==2009)

# bind with historical data
ppt_daily_all <- full_join(data_hist, ppt_daily) |> 
  mutate(ppt_mm = coalesce(tot_ppt_mm, precip_mm),
         station = coalesce(station, as.character(station_id))) |> 
  select(station, date, DOY, DOWY, WY, ppt_mm)


# Make Monthly Precip -----------------------------------------------------

ppt_mon <- ppt_daily_all |>
  mutate(month = lubridate::month(date)) |> 
  group_by(WY, month) |>
  summarize("tot_ppt_mm"=sum(ppt_mm, na.rm = T)) |> 
  mutate(mon_wy = factor(month, levels = c(10,11,12,1,2,3,4,5,6,7,8,9)))

ppt_wk <- ppt_daily_all |>
  mutate(week = week(date)) |> 
  group_by(WY, week) |>
  summarize("tot_ppt_mm"=sum(ppt_mm, na.rm = T)) |> 
  mutate(wk_wy = factor(week, levels = c(40:53, 1:39)))

# Plot Precip -------------------------------------------------------------

# max ppt: barplot of last 20 yrs
gg_ppt_mon <- ggplot() +
  geom_col(data=ppt_mon |> filter(WY > as.integer(format(Sys.Date(), "%Y"))-29), 
           aes(x=mon_wy, y=tot_ppt_mm, group=mon_wy), 
           fill="steelblue", alpha=0.95, color="skyblue") +
  # current wy
  geom_col(data=ppt_mon |> filter(WY==as.integer(wtr_yr(Sys.Date()))),
           aes(x=mon_wy, y=tot_ppt_mm, group=mon_wy), 
           fill="coral", alpha=0.95, color="maroon") +
  geom_hline(yintercept = 50.8, color="gray50", alpha=0.4, lwd=0.7)+
  labs(x="Months (by Water Year: Oct 1 - Sep 30)", y="Monthly Precip (mm)", 
       title = "Davis CA: Precip by Month (gray line = 2 in)")+
  hrbrthemes::theme_ft_rc() +
  theme(axis.text.x = element_text(angle=90, vjust = 0.5))+
  facet_wrap(.~WY)
 
ggsave(gg_ppt_mon, filename = "figures/precip_by_month_last_20yrs_current.png", width = 11, height = 8.5, dpi=300)

# weekly through time
gg_ppt_wk <- ggplot() +
  geom_col(data=ppt_wk |> filter(WY > as.integer(format(Sys.Date(), "%Y"))-29),
           aes(x=wk_wy, y=tot_ppt_mm, group=WY),
           fill="steelblue", alpha=0.95, color="skyblue") +
  geom_col(data=ppt_wk |> filter(WY==as.integer(wtr_yr(Sys.Date()))),
           aes(x=wk_wy, y=tot_ppt_mm), 
           fill="coral", alpha=0.95, color="maroon") +
  labs(x="Weeks (by Water Year: Oct 1 - Sep 30)", y="Weekly Precip (mm)", 
       title = "Davis CA: Precip by Week (gray line = 2 in)")+
  hrbrthemes::theme_ft_rc() +
  theme(axis.text.x = element_blank())+
  facet_wrap(.~WY)

ggsave(gg_ppt_wk, filename = "figures/precip_by_week_1981_current.png", width = 11, height = 8.5, dpi=300)
  
# last 30 years
gg_ppt_wk_trim <- ggplot() +
  geom_col(data=ppt_wk |> filter(WY>1990),
           aes(x=wk_wy, y=tot_ppt_mm, group=WY),
           fill="steelblue", alpha=0.8, color="skyblue") +
  geom_col(data=ppt_wk |> filter(WY==as.integer(wtr_yr(Sys.Date()))),
           aes(x=wk_wy, y=tot_ppt_mm), 
           fill="coral", alpha=0.8, color="maroon") +
  labs(x="Weeks (by Water Year: Oct 1 - Sep 30)", y="Weekly Precip (mm)", 
       title = "Davis CA: Precip by Week (gray line = 2 in)")+
  hrbrthemes::theme_ft_rc() +
  theme(axis.text.x = element_blank())+
  facet_wrap(.~WY)

# combine
#plot_out <- gg_ppt_wk_trim / gg_ppt_mon

# save it!
#ggsave(plot_out, filename = snakemake@output[[1]], width = 11, height = 8.5, dpi=300)

#ggsave(filename = glue("figures/monthly_weekly_precip_davis_ca_updated_{Sys.Date()}.png"), width = 11, height = 8.5, dpi=300)
