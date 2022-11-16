## ---- include=FALSE-----------------------------------------------------------
knitr::opts_chunk$set(message = FALSE)

## ---- results='hold'----------------------------------------------------------
library(yfR)

# set options for algorithm
my_ticker <- 'GM'
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

# fetch data
df_yf <- yf_get(tickers = my_ticker, 
                first_date = first_date,
                last_date = last_date)

# output is a tibble with data
head(df_yf)

## -----------------------------------------------------------------------------
library(yfR)
library(ggplot2)

my_ticker <- c('TSLA', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get(tickers = my_ticker, 
                         first_date = first_date,
                         last_date = last_date)


p <- ggplot(df_yf_multiple, aes(x = ref_date, y = price_adjusted,
                                color = ticker)) + 
  geom_line()

p

## -----------------------------------------------------------------------------
library(yfR)
library(ggplot2)
library(dplyr)

my_ticker <- 'GE'
first_date <- '2005-01-01'
last_date <- Sys.Date()

df_dailly <- yf_get(tickers = my_ticker, 
                    first_date, last_date, 
                    freq_data = 'daily') %>%
  mutate(freq = 'daily')

df_weekly <- yf_get(tickers = my_ticker, 
                    first_date, last_date, 
                    freq_data = 'weekly') %>%
  mutate(freq = 'weekly')

df_monthly <- yf_get(tickers = my_ticker, 
                     first_date, last_date, 
                     freq_data = 'monthly') %>%
  mutate(freq = 'monthly')

df_yearly <- yf_get(tickers = my_ticker, 
                    first_date, last_date, 
                    freq_data = 'yearly') %>%
  mutate(freq = 'yearly')

# bind it all together for plotting
df_allfreq <- bind_rows(
  list(df_dailly, df_weekly, df_monthly, df_yearly)
) %>%
  mutate(freq = factor(freq, 
                       levels = c('daily', 
                                  'weekly',
                                  'monthly',
                                  'yearly'))) # make sure the order in plot is right

p <- ggplot(df_allfreq, aes(x = ref_date, y = price_adjusted)) + 
  geom_line() + 
  facet_grid(freq ~ ticker) + 
  theme_minimal() + 
  labs(x = '', y = 'Adjusted Prices')

print(p)

## -----------------------------------------------------------------------------
library(yfR)
library(ggplot2)

my_ticker <- c('TSLA', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get(tickers = my_ticker, 
                         first_date = first_date,
                         last_date = last_date)

print(df_yf_multiple)

l_wide <- yf_convert_to_wide(df_yf_multiple)

names(l_wide)

prices_wide <- l_wide$price_adjusted
head(prices_wide)

