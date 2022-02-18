# download Davis climate data

library(purrr)
library(janitor)
library(dplyr)
library(glue)
library(readr)
library(lubridate)
library(ggplot2)
library(patchwork)


# The Data ----------------------------------------------------------------

data <- read_csv(file = "data_clean/davis_clim_data.csv.gz")

data_hist <- read_csv(file = "data_raw/davis_daily_historical_1980_2021.csv", skip = 63) %>%
  clean_names() %>%
  mutate(date = ymd(date)) %>%
  rename(precip_mm=precip, air_max_c = air_max, air_min_c=min_7,
         soil_max_c = soil_max, soil_min_c=min_15,
         solar_wsqm = solar) %>%
  select(station, date, precip_mm, air_max_c:air_min_c, soil_max_c:soil_min_c, solar_wsqm)
data_hist <- data_hist %>% wateRshedTools::add_WYD("date")

# Clean Data ----------------------------------------------------------------

data <- data %>% wateRshedTools::add_WYD("datetime_hr") %>% 
  mutate(date = as.Date(datetime_hr), .before = datetime_hr)

# add decade function
#f_floor_decade <- function(x){ return(x - x %% 10) }
# add decade
#data$decade <- f_floor_decade(data$WY)

# Make Daily Precip ----------------------------------------------------------

# clean and summarize subdaily to daily
ppt_daily <- data %>% filter(metric_id == "CT_Rain_Tot24") %>% 
  group_by(date, station_id, metric_id, DOY, WY, DOWY) %>% 
  summarise(tot_ppt_mm = max(value_hr, na.rm=TRUE), # take max of last 24 hrs
            tot_ppt_in = tot_ppt_mm * 0.0393701) %>% 
  ungroup() %>% 
  mutate(week = as.factor(week(date)),
         month = as.factor(month(date))) %>% 
  # reorder weeks/months for Water Years
  mutate(month = forcats::lvls_reorder(month, c(10:12,1:9)),
         week = forcats::lvls_reorder(week, c(40:53, 1:39))) %>% 
  # drop 2009 since it's incomplete
  filter(!WY==2009)

# bind with historical data
ppt_daily_all <- full_join(data_hist, ppt_daily) %>% 
  mutate(ppt_mm = coalesce(tot_ppt_mm, precip_mm),
         station = coalesce(station, as.character(station_id))) %>% 
  select(station, date, DOY, DOWY, WY, ppt_mm)

summary(ppt_daily_all)

# test
ppt_daily_all %>% ggplot(data=.) + geom_line(aes(date, ppt_mm), color="blue") 
# # make a xwalk for water year org
# xwalk <-ppt_daily_all %>% select(date, WY) %>% mutate(month = month(date), wk = week(date)) %>% select(month, wk) %>% distinct() %>% 
#   mutate(mon_wy = factor(month, levels = c(10,11,12,1,2,3,4,5,6,7,8,9)),
#          wk_wy = factor(wk, levels = c(40:53, 1:39)))


# Make Monthly Precip -----------------------------------------------------

ppt_mon <- ppt_daily_all %>%
  mutate(month = lubridate::month(date)) %>% 
  group_by(WY, month) %>%
  summarize("tot_ppt_mm"=sum(ppt_mm, na.rm = T)) %>% 
  mutate(mon_wy = factor(month, levels = c(10,11,12,1,2,3,4,5,6,7,8,9)))

ppt_wk <- ppt_daily_all %>%
  mutate(week = week(date)) %>% 
  group_by(WY, week) %>%
  summarize("tot_ppt_mm"=sum(ppt_mm, na.rm = T)) %>% 
  mutate(wk_wy = factor(week, levels = c(40:53, 1:39)))

# Plot Precip -------------------------------------------------------------

# max ppt: barplot
gg_ppt_mon <- ggplot() +
  geom_col(data=ppt_mon, 
           aes(x=mon_wy, y=tot_ppt_mm, group=mon_wy), 
           fill="steelblue", alpha=0.8, color="skyblue") +
  geom_col(data=ppt_mon %>% filter(WY==2022),
           aes(x=mon_wy, y=tot_ppt_mm, group=mon_wy), 
           fill="coral", alpha=0.8, color="maroon") +
  labs(x="Month", y="Total Precip (mm)", subtitle="Precip by Water Year") + 
  ggdark::dark_theme_bw() +
  #scale_x_continuous(breaks=c(1, 3, 5, 7, 9, 11,12), labels = c(1, 3, 5, 7, 9,11,12), limits = c(0,12), expand = c(0.005, 0.005)) +
  theme(axis.text.x = element_text(angle=90, vjust = 0.5))+
  facet_wrap(.~WY)
gg_ppt_mon

# weekly through time
gg_ppt_wk <- ggplot() +
  geom_col(data=ppt_wk,
           aes(x=wk_wy, y=tot_ppt_mm, group=WY),
           fill="steelblue", alpha=0.8, color="skyblue") +
  geom_col(data=ppt_wk %>% filter(WY==2022),
           aes(x=wk_wy, y=tot_ppt_mm), 
           fill="coral", alpha=0.8, color="maroon") +
  labs(x="Weeks (by Water Year: Oct 1 - Sep 30)", y="Weekly Precip (in)", 
       title = "Davis CA: Precip by Week")+
  ggdark::dark_theme_bw() +
  theme(axis.text.x = element_blank())+
  facet_wrap(.~WY)
gg_ppt_wk

# Look at Fall only
gg_ppt_daily <- ppt_daily %>% filter(month %in% c("10","11","12", "1", "2")) %>% ungroup() %>% 
  ggplot() + geom_col(aes(x=as.factor(WY), y=tot_ppt_in, fill=month))+
  ggdark::dark_theme_classic() +
  ggthemes::scale_fill_few(palette = "Light", "Month") +
  labs(title = "Davis CA: Winter Precip", y="Precip (in)", x="Water Year",
       caption = glue("Data Source: <http://atm.ucdavis.edu/weather/> \nupdated: {Sys.Date()}"))
 
# combine
plot_out <- gg_ppt_wk / gg_ppt_daily
plot_out

# save it!
ggsave(plot_out, filename = snakemake@output[[1]], width = 11, height = 8.5, dpi=300)
#ggsave(filename = glue("figures/monthly_weekly_precip_davis_ca_updated_{Sys.Date()}.png"), width = 11, height = 8.5, dpi=300)
