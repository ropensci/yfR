
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Codecov test
coverage](https://codecov.io/gh/msperlin/yfR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/msperlin/yfR?branch=main)
[![R build
(rcmdcheck)](https://github.com/msperlin/yfR/workflows/R-CMD-check/badge.svg)](https://github.com/msperlin/yfR/actions)
[![Status at rOpenSci Software Peer
Review](https://badges.ropensci.org/523_status.svg)](https://github.com/ropensci/software-review/issues/523)
<!-- badges: end -->

# Motivation

`yfR` is the second and backwards-incompatible version of
[BatchGetSymbols](https://CRAN.R-project.org/package=BatchGetSymbols).
In a nutshell, it provides access to daily stock prices from [Yahoo
Finance](https://finance.yahoo.com/), a vast repository with financial
data around the globe. Yahoo Finance cover a large number of markets and
assets, being used extensively for importing price datasets used in
academic research and teaching.

Package `yfR` is based on [quantmod](https://www.quantmod.com/) and uses
one of its functions (`quantmod::getSymbols`) for fetching data from
Yahoo Finance. The main innovation in `yfR` is in the organization of
the imported financial data and using a local caching system and
parallel computing for speeding up large scale download of datasets from
Yahoo Finance.

See full documentation [here](https://github.com/msperlin/yfR).

## Features

-   Fetchs daily/weekly/monthly/annual stock prices/returns from yahoo
    finance and outputs a dataframe (tibble) in the long format (stacked
    data);

-   A new feature called “collections” facilitates download of multiple
    tickers from a particular market/index. You can, for example,
    download data for all stocks in the SP500 index with a simple call
    to `yf_collection_get()`;

-   A session-persistent smart cache system is available by default.
    This means that the data is saved locally and only missing portions
    are downloaded, if needed.

-   All dates are compared to a benchmark ticker such as SP500 and,
    whenever an individual asset does not have a sufficient number of
    dates, the software drops it from the output. This means you can
    choose to ignore tickers with high number of missing dates.

-   A customized function called `yf_convert_to_wide()` can transform
    the long dataframe into a wide format (tickers as columns), much
    used in portfolio optimization. The output is a list where each
    element is a different target variable (prices, returns, volumes).

-   Parallel computing with package `furrr` is available, speeding up
    the data importation process.

## Differences from [BatchGetSymbols](https://github.com/msperlin/BatchGetSymbols)

Package `BatchgetSymbols` was developed back in 2016, with many bad
structural choices from my part. Since then, I learned more about R and
its ecosystem, resulting in better and more maintainable code. However,
it is impossible to keep compatibility with the changes I wanted to
make, which is why I decided to develop a new (and fresh) package.

Here are the main differences between `yfR` (new) and `BatchGetSymbols`
(old):

-   All input arguments are now formatted as “snake_case” and not
    “dot.case”. For example, the argument for the first date of data
    importation in `yfR::yf_get()` is `first_date`, and not
    `first.date`, as used in `BatchGetSymbols::BatchGetSymbols`.

-   A new feature called “collection”, which allows for easy download of
    a collection of tickers. For example, you can download price data
    for all components of the SP500 by simply calling
    `yfR::yf_collection_get("SP500")`.

-   All function have been renamed for a common API notation. For
    example, `BatchGetSymbols::BatchGetSymbols` is now `yfR::yf_get()`.
    Likewise, the function for fetching collections is
    `yfR::yf_collection_get()`.

-   The output of `yfR::yf_get()` is always a tibble with the price data
    (and not a list as in `BatchGetSymbols::BatchGetSymbols`). If one
    wants the tibble with a summary of the importing process, it is
    available as an attribute of the output (see function
    `base::attributes`)

-   New and prettier status messages using package `cli`

## Warnings

-   Yahoo finance data is far from perfect or reliable, specially for
    individual stocks. In my experience, using it for research code with
    stock **indices** is fine and I can match it with other data
    sources. But, adjusted stock prices for **individual assets** is
    messy as stock events such as splits or dividends are not properly
    registered. I was never able to match it with other data sources,
    specially for long time periods with lots of corporate events. My
    advice is to **never use the yahoo finance data of individual stocks
    in production** (research papers or academic documents – thesis and
    dissertations). If adjusted price data of individual stocks is
    important for your research, **use other data sources** such as
    [EOD](https://eodhistoricaldata.com/), [SimFin](https://simfin.com/)
    or [Economática](https://economatica.com/).

## Installation

    # CRAN (not yet available)
    #install.packages('yfR')

    # Github (dev version)
    devtools::install_github('msperlin/yfR')

## Examples

### Fetching a single stock price

``` r
library(yfR)

# set options for algorithm
my_ticker <- 'FB'
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

# fetch data
df_yf <- yf_get(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 1 stocks | 2022-04-02 --> 2022-05-02 (30 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for FB
#> !    - not cached
#> ✔    - cache saved successfully
#> ✔    - got 19 valid rows (2022-04-04 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Good job msperlin!
#> ℹ Binding price data

# output is a tibble with data
head(df_yf)
#> # A tibble: 6 × 10
#>   ticker ref_date   price_open price_high price_low price_close   volume
#>   <chr>  <date>          <dbl>      <dbl>     <dbl>       <dbl>    <dbl>
#> 1 FB     2022-04-04       226.       234.      226.        234. 28054800
#> 2 FB     2022-04-05       234.       237.      231.        232. 29727200
#> 3 FB     2022-04-06       227.       229.      221.        223. 28995100
#> 4 FB     2022-04-07       224.       226.      219.        223. 21037200
#> 5 FB     2022-04-08       222.       225.      220.        222. 18363700
#> 6 FB     2022-04-11       218.       221.      215.        216. 20516600
#> # … with 3 more variables: price_adjusted <dbl>, ret_adjusted_prices <dbl>,
#> #   ret_closing_prices <dbl>
```

### Fetching many stock prices

``` r
library(yfR)
library(ggplot2)

my_ticker <- c('FB', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get(tickers = my_ticker, 
                              first_date = first_date,
                              last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2022-01-22 --> 2022-05-02 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✔    - found cache file (2022-04-04 --> 2022-04-29)
#> !    - need new data (cache doesnt match query)
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- You got it msperlin!
#> ℹ (2/3) Fetching data for GM
#> !    - not cached
#> ✔    - cache saved successfully
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Youre doing good!
#> ℹ (3/3) Fetching data for MMM
#> !    - not cached
#> ✔    - cache saved successfully
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Time for some tea?
#> ℹ Binding price data


p <- ggplot(df_yf_multiple, 
            aes(x = ref_date, y = price_adjusted,
                color = ticker)) + 
  geom_line()

print(p)
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

### Fetching collections of prices

Collections are just a bundle of tickers pre-organized in the package.
For example, collection `SP500` represents the current composition of
the SP500 index.

``` r
library(yfR)

df_yf <- yf_collection_get("SP500", 
                           first_date = Sys.Date() - 30,
                           last_date = Sys.Date())

head(df_yf)
```

### Fetching daily/weekly/monthly/yearly price data

``` r
library(yfR)
library(ggplot2)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

my_ticker <- 'GE'
first_date <- '2010-01-01'
last_date <- Sys.Date()

df_dailly <- yf_get(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'daily') %>%
  mutate(freq = 'daily')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-05-02 (4504 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> !    - not cached
#> ✔    - cache saved successfully
#> ✔    - got 3103 valid rows (2010-01-04 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Mais faceiro que guri de bombacha nova!
#> ℹ Binding price data


df_weekly <- yf_get(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'weekly') %>%
  mutate(freq = 'weekly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-05-02 (4504 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✔    - found cache file (2010-01-04 --> 2022-04-29)
#> ✔    - got 3103 valid rows (2010-01-04 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Well done msperlin!
#> ℹ Binding price data

df_monthly <- yf_get(tickers = my_ticker, 
                          first_date, last_date, 
                          freq_data = 'monthly') %>%
  mutate(freq = 'monthly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-05-02 (4504 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✔    - found cache file (2010-01-04 --> 2022-04-29)
#> ✔    - got 3103 valid rows (2010-01-04 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Good stuff!
#> ℹ Binding price data

df_yearly <- yf_get(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'yearly') %>%
  mutate(freq = 'yearly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-05-02 (4504 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✔    - found cache file (2010-01-04 --> 2022-04-29)
#> ✔    - got 3103 valid rows (2010-01-04 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Well done msperlin!
#> ℹ Binding price data

df_allfreq <- bind_rows(
  list(df_dailly, df_weekly, df_monthly, df_yearly)
) %>%
  mutate(freq = factor(freq, 
                       levels = c('daily', 
                                  'weekly',
                                  'monthly',
                                  'yearly'))) # make sure the order in plot is right

p <- ggplot(df_allfreq, aes(x=ref_date, y = price_adjusted)) + 
  geom_point() + geom_line() + facet_grid(freq ~ ticker) + 
  theme_minimal() + 
  labs(x = '', y = 'Adjusted Prices')

print(p)
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

### Changing format to wide

``` r
library(yfR)
library(ggplot2)
library(kableExtra)
#> 
#> Attaching package: 'kableExtra'
#> The following object is masked from 'package:dplyr':
#> 
#>     group_rows

my_ticker <- c('FB', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get(tickers = my_ticker, 
                              first_date = first_date,
                              last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2022-01-22 --> 2022-05-02 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✔    - found cache file (2022-01-24 --> 2022-04-29)
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Good job msperlin!
#> ℹ (2/3) Fetching data for GM
#> ✔    - found cache file (2022-01-24 --> 2022-04-29)
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Time for some tea?
#> ℹ (3/3) Fetching data for MMM
#> ✔    - found cache file (2022-01-24 --> 2022-04-29)
#> ✔    - got 68 valid rows (2022-01-24 --> 2022-04-29)
#> ✔    - got 100% of valid prices -- Time for some tea?
#> ℹ Binding price data

l_wide <- yf_convert_to_wide(df_yf_multiple)

prices_wide <- l_wide$price_adjusted

head(prices_wide)
#> # A tibble: 6 × 4
#>   ref_date      FB    GM   MMM
#>   <date>     <dbl> <dbl> <dbl>
#> 1 2022-01-24  309.  52.6  171.
#> 2 2022-01-25  300.  51.9  172.
#> 3 2022-01-26  295.  52.3  168.
#> 4 2022-01-27  295.  51.5  169.
#> 5 2022-01-28  302.  50.2  162.
#> 6 2022-01-31  313.  52.7  164.
```
