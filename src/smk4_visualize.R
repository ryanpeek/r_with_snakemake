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

print(snakemake@input[[1]]) 
infile <- snakemake@input[[1]]

#data <- read_csv(file = "data_clean/davis_clim_data.csv.gz")
data <- read_csv(file = infile)

# ddata <- read_csv(file = "data_raw/davis_daily_historical_1980_2021.csv", skip = 63) %>%
#   clean_names() %>%
#   mutate(date = ymd(date)) %>%
#   rename(precip_mm=precip, air_max_c = air_max, air_min_c=min_7,
#          soil_max_c = soil_max, soil_min_c=min_15,
#          solar_wsqm = solar) %>%
#   select(station, date, precip_mm, air_max_c:air_min_c, soil_max_c:soil_min_c, solar_wsqm)
# ddata <- ddata %>% wateRshedTools::add_WYD("date")

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

# test
# ppt_daily %>% ggplot(data=.) + geom_line(aes(date, tot_ppt_in), color="blue") 

# Make Monthly Precip -----------------------------------------------------

ppt_mon <- ppt_daily %>%
  group_by(WY, month) %>%
  summarize("tot_ppt_in"=sum(tot_ppt_in, na.rm = T))

ppt_wk <- ppt_daily %>%
  group_by(WY, week) %>%
  summarize("tot_ppt_in"=sum(tot_ppt_in, na.rm = T))

# Plot Precip -------------------------------------------------------------

# max ppt: barplot
gg_ppt_mon <- ggplot() +
  geom_col(data=ppt_mon, 
           aes(x=month, y=tot_ppt_in, group=month), 
           fill="steelblue", alpha=0.8, color="skyblue") +
  geom_col(data=ppt_mon %>% filter(WY==2022),
           aes(x=month, y=tot_ppt_in, group=month), 
           fill="coral", alpha=0.8, color="maroon") +
  labs(x="Month", y="Total Precip (in)", subtitle="Precip by Water Year") + 
  ggdark::dark_theme_bw() +
  theme(axis.text.x = element_text(angle=90, vjust = 0.5))+
  facet_wrap(.~WY)

# weekly through time
gg_ppt_wk <- ggplot() +
  geom_col(data=ppt_wk,
           aes(x=week, y=tot_ppt_in, group=WY),
           fill="steelblue", alpha=0.8, color="skyblue") +
  geom_col(data=ppt_wk %>% filter(WY==2022),
           aes(x=week, y=tot_ppt_in), 
           fill="coral", alpha=0.8, color="maroon") +
  labs(x="Weeks (by Water Year: Oct 1 - Sep 30)", y="Weekly Precip (in)", 
       title = "Davis CA: Precip by Week")+
  ggdark::dark_theme_bw() +
  theme(axis.text.x = element_blank())+
  facet_wrap(.~WY)

# Look at Fall only
gg_ppt_daily <- ppt_daily %>% filter(month %in% c("10","11","12")) %>% ungroup() %>% 
  ggplot() + geom_col(aes(x=as.factor(WY), y=tot_ppt_in, fill=month))+
  ggdark::dark_theme_classic() +
  ggthemes::scale_fill_few(palette = "Light", "Month") +
  labs(title = "Davis CA: Fall Precip", y="Precip (in)", x="Water Year",
       caption = glue("Data Source: <http://atm.ucdavis.edu/weather/> \nupdated: {Sys.Date()}"))
 
# combine
plot_out <- gg_ppt_wk / gg_ppt_daily

# save it!
ggsave(plot_out, filename = snakemake@output[[1]], width = 11, height = 8.5, dpi=300)
#ggsave(filename = glue("figures/monthly_weekly_precip_davis_ca_updated_{Sys.Date()}.png"), width = 11, height = 8.5, dpi=300)
