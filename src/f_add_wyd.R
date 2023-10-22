#' A function to add water year day
#'
#' @export
#' @name f_add_wyd a function to add water year info from a vector of dates
#' @author Ryan Peek
#' @import lubridate
#' @param date,start_mon a date or vector of dates, the start month as an integer
#' @returns a vector of formatted dates
#' @examples
#'
#' get_photo_list(photo_path)

# function for water year day
f_add_wyd <- function(date, start_mon = 10L){

  start_yr <- year(date) - (month(date) < start_mon)
  start_date <- make_date(start_yr, start_mon, 1L)
  wyd <- as.integer(date - start_date + 1L)
  # deal with leap year
  offsetyr <- ifelse(lubridate::leap_year(date), 1, 0) # Leap Year offset
  adj_wyd <- ifelse(offsetyr==1 & month(date) >= start_mon, wyd - 1, wyd)
  return(adj_wyd)
}

# function for water year week
f_add_wyweek <- function(wyday){
  wyw <- wyday %/% 7 + 1
  return(wyw)
}

wtr_yr <- function(dates, start_month=10) {
  # Convert dates into POSIXlt
  dates.posix = as.POSIXlt(dates)
  # Year offset
  offset = ifelse(dates.posix$mon >= start_month - 1, 1, 0)
  # Water year
  adj.year = dates.posix$year + 1900 + offset
  # Return the water year
  return(adj.year)
}


# add Water Year Day (Day 1 starting Oct 1)
dowy<-function(YYYYMMDD_HMS) {   # Dates must be POSIXct
  YYYYMMDD_HMS<-YYYYMMDD_HMS
  #wy<-wtr_yr(YYYYMMDD_HMS)
  doy<-lubridate::yday(YYYYMMDD_HMS)

  # make DOWY
  offsetday = ifelse(month(YYYYMMDD_HMS) > 9, -273, 92)
  DOWY = doy + offsetday

  # adjust for leap year
  offsetyr = ifelse(lubridate::leap_year(YYYYMMDD_HMS), 1, 0) # Leap Year offset
  adj.wyd = ifelse(offsetyr==1 & doy > 274, DOWY - 1, DOWY)

  return(adj.wyd)
}


# add DOY to df
add_WYD <- function(df, datecolumn){ # provide either number or quoted name for date POSIXct col
  datecolumn=datecolumn
  df["DOY"] <- as.integer(sapply(df[,c(datecolumn)], yday))
  df["WY"] <- as.integer(sapply(df[,c(datecolumn)], wtr_yr))
  df["DOWY"] <- as.integer(sapply(df[,c(datecolumn)], dowy))
  return(df)

}
