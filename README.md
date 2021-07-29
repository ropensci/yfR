
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://cranlogs.r-pkg.org/badges/yfR)](https://CRAN.R-project.org/yfR)

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

# Motivation

`yfR` is the second and backwards-incompatible version of
[BatchGetSymbols](https://CRAN.R-project.org/package=BatchGetSymbols).
It provides access to daily stock prices from [Yahoo
Finance](https://finance.yahoo.com/), a vast repository with data around
the globe. Moreover, *yfR* allows large scales downloads of data, using
a local caching system for speeding up the process.

## Features

-   Fetchs daily/weekly/monthly/annual stock prices (and returns) from
    yahoo finance and returns a dataframe in the long format;
-   A session-persistent smart cache system is available by default.
    This means that the data is saved locally and only missing portions
    are downloaded, if needed.
-   All dates are compared to a benchmark ticker such as SP500 and,
    whenever an individual asset does not have a sufficient number of
    dates, the software drops it from the output. This means you can
    choose to ignore tickers with high number of missing dates.
-   A customized function called `yf_convert_to_wide()` can transform
    the long dataframe into a wide format (tickers as columns).
-   Parallel computing is available, speeding up the data importation
    process.

## Warnings

-   Yahoo finance data is far from perfect or reliable, specially for
    individual stocks. In my experience, using it for research code with
    stock **indices** is fine and I can match it with other data
    sources. But, adjusted stock prices for **individual assets** is
    messy as stock events such as splits or dividends are not properly
    registered. I was never able to match it with other data sources,
    specially for long time periods with lots of corporate events. My
    advice is to never use the data of individual stocks in production
    (research papers or academic documents – thesis and dissertations).

## Installation

    # CRAN (not yet available)
    #install.packages('yfR')

    # Github (dev version)
    devtools::install_github('msperlin/yfR')

## Examples

### Fetching a single stock price

``` r
library(yfR)
#> 

my_ticker <- 'FB'
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

df_yf <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 1 stocks | 2021-06-29 --> 2021-07-29 (30 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for FB
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 21 valid rows (2021-06-29 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Youre doing good!

str(df_yf)
#> tibble [21 × 10] (S3: tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:21] "FB" "FB" "FB" "FB" ...
#>  $ ref_date           : Date[1:21], format: "2021-06-29" "2021-06-30" ...
#>  $ price_open         : num [1:21] 356 352 347 355 356 ...
#>  $ price_high         : num [1:21] 357 353 355 356 359 ...
#>  $ price_low          : num [1:21] 349 347 346 353 349 ...
#>  $ price_close        : num [1:21] 352 348 354 355 353 ...
#>  $ volume             : num [1:21] 21417300 15107500 17137000 11521300 13488500 ...
#>  $ price_adjusted     : num [1:21] 352 348 354 355 353 ...
#>  $ ret_adjusted_prices: num [1:21] NA -0.011879 0.019211 0.000875 -0.005413 ...
#>  $ ret_closing_prices : num [1:21] NA -0.011879 0.019211 0.000875 -0.005413 ...
#>  - attr(*, "df_control")= tibble [1 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr "FB"
#>   ..$ dl_status           : chr "OK"
#>   ..$ n_rows              : int 21
#>   ..$ perc_benchmark_dates: num 1
#>   ..$ threshold_decision  : chr "KEEP"
```

### Fetching many stock prices

``` r
library(yfR)
library(ggplot2)

my_ticker <- c('FB', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2021-04-20 --> 2021-07-29 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✓    - found cache file (2021-06-29 --> 2021-07-28)
#> !    - need new data (cache doesnt match query)
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Looking good!
#> ℹ (2/3) Fetching data for GM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Time for some tea?
#> ℹ (3/3) Fetching data for MMM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- All OK!

str(df_yf_multiple)
#> tibble [210 × 10] (S3: tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:210] "FB" "FB" "FB" "FB" ...
#>  $ ref_date           : Date[1:210], format: "2021-04-20" "2021-04-21" ...
#>  $ price_open         : num [1:210] 302 302 301 299 303 ...
#>  $ price_high         : num [1:210] 305 302 303 303 306 ...
#>  $ price_low          : num [1:210] 297 297 296 297 302 ...
#>  $ price_close        : num [1:210] 303 301 297 301 303 ...
#>  $ volume             : num [1:210] 16796400 14863500 16375400 17536800 16172600 ...
#>  $ price_adjusted     : num [1:210] 303 301 297 301 303 ...
#>  $ ret_adjusted_prices: num [1:210] NA -0.0039 -0.01642 0.01555 0.00634 ...
#>  $ ret_closing_prices : num [1:210] NA -0.0039 -0.01642 0.01555 0.00634 ...
#>  - attr(*, "df_control")= tibble [3 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr [1:3] "FB" "GM" "MMM"
#>   ..$ dl_status           : chr [1:3] "OK" "OK" "OK"
#>   ..$ n_rows              : int [1:3] 70 70 70
#>   ..$ perc_benchmark_dates: num [1:3] 1 1 1
#>   ..$ threshold_decision  : chr [1:3] "KEEP" "KEEP" "KEEP"

p <- ggplot(df_yf_multiple, aes(x = ref_date, y = price_adjusted,
                       color = ticker)) + 
  geom_line()

p
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

### Fetching collections of prices

Collections are just a bundle of tickers pre-organized in the package.
For example, collection `SP500` represents the current composition of
the SP500 index.

``` r
library(yfR)

df_yf <- yf_get_collection("SP500")

str(df_yf)
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

df_dailly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'daily') |>
  mutate(freq = 'daily')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-07-29 (4227 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 2912 valid rows (2010-01-04 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Good stuff!
  
  
df_weekly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'weekly') |>
  mutate(freq = 'weekly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-07-29 (4227 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-07-28)
#> ✓    - got 2912 valid rows (2010-01-04 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Got it!

df_monthly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'monthly') |>
  mutate(freq = 'monthly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-07-29 (4227 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-07-28)
#> ✓    - got 2912 valid rows (2010-01-04 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Good stuff!

df_yearly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'yearly') |>
  mutate(freq = 'yearly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-07-29 (4227 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-07-28)
#> ✓    - got 2912 valid rows (2010-01-04 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Time for some tea?

df_allfreq <- bind_rows(
  list(df_dailly, df_weekly, df_monthly, df_yearly)
) |>
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

df_yf_multiple <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2021-04-20 --> 2021-07-29 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✓    - found cache file (2021-04-20 --> 2021-07-28)
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- You got it msperlin!
#> ℹ (2/3) Fetching data for GM
#> ✓    - found cache file (2021-04-20 --> 2021-07-28)
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- You got it msperlin!
#> ℹ (3/3) Fetching data for MMM
#> ✓    - found cache file (2021-04-20 --> 2021-07-28)
#> ✓    - got 70 valid rows (2021-04-20 --> 2021-07-28)
#> ✓    - got 100% of valid prices -- Time for some tea?

l_wide <- yf_converto_to_wide(df_yf_multiple)

prices_wide <- l_wide$price_adjusted

knitr::kable(prices_wide)
```

<table>
<thead>
<tr>
<th style="text-align:left;">
ref_date
</th>
<th style="text-align:right;">
FB
</th>
<th style="text-align:right;">
GM
</th>
<th style="text-align:right;">
MMM
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2021-04-20
</td>
<td style="text-align:right;">
302.65
</td>
<td style="text-align:right;">
55.77
</td>
<td style="text-align:right;">
196.8514
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-21
</td>
<td style="text-align:right;">
301.47
</td>
<td style="text-align:right;">
57.49
</td>
<td style="text-align:right;">
199.4126
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-22
</td>
<td style="text-align:right;">
296.52
</td>
<td style="text-align:right;">
56.66
</td>
<td style="text-align:right;">
199.4324
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-23
</td>
<td style="text-align:right;">
301.13
</td>
<td style="text-align:right;">
57.53
</td>
<td style="text-align:right;">
200.7229
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-26
</td>
<td style="text-align:right;">
303.04
</td>
<td style="text-align:right;">
58.21
</td>
<td style="text-align:right;">
198.1717
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-27
</td>
<td style="text-align:right;">
303.57
</td>
<td style="text-align:right;">
58.97
</td>
<td style="text-align:right;">
193.0295
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-28
</td>
<td style="text-align:right;">
307.10
</td>
<td style="text-align:right;">
58.55
</td>
<td style="text-align:right;">
194.4987
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-29
</td>
<td style="text-align:right;">
329.51
</td>
<td style="text-align:right;">
56.57
</td>
<td style="text-align:right;">
197.5959
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-30
</td>
<td style="text-align:right;">
325.08
</td>
<td style="text-align:right;">
57.22
</td>
<td style="text-align:right;">
195.6999
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-03
</td>
<td style="text-align:right;">
322.58
</td>
<td style="text-align:right;">
57.15
</td>
<td style="text-align:right;">
197.1591
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-04
</td>
<td style="text-align:right;">
318.36
</td>
<td style="text-align:right;">
55.34
</td>
<td style="text-align:right;">
197.9235
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-05
</td>
<td style="text-align:right;">
315.02
</td>
<td style="text-align:right;">
57.58
</td>
<td style="text-align:right;">
199.9685
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-06
</td>
<td style="text-align:right;">
320.02
</td>
<td style="text-align:right;">
58.72
</td>
<td style="text-align:right;">
200.9314
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-07
</td>
<td style="text-align:right;">
319.08
</td>
<td style="text-align:right;">
58.99
</td>
<td style="text-align:right;">
201.5866
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-10
</td>
<td style="text-align:right;">
305.97
</td>
<td style="text-align:right;">
57.41
</td>
<td style="text-align:right;">
205.8154
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-11
</td>
<td style="text-align:right;">
306.53
</td>
<td style="text-align:right;">
55.73
</td>
<td style="text-align:right;">
202.2318
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-12
</td>
<td style="text-align:right;">
302.55
</td>
<td style="text-align:right;">
53.76
</td>
<td style="text-align:right;">
197.4173
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-13
</td>
<td style="text-align:right;">
305.26
</td>
<td style="text-align:right;">
54.60
</td>
<td style="text-align:right;">
201.9241
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-14
</td>
<td style="text-align:right;">
315.94
</td>
<td style="text-align:right;">
56.00
</td>
<td style="text-align:right;">
202.8870
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-17
</td>
<td style="text-align:right;">
315.46
</td>
<td style="text-align:right;">
56.04
</td>
<td style="text-align:right;">
203.6117
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-18
</td>
<td style="text-align:right;">
309.96
</td>
<td style="text-align:right;">
55.89
</td>
<td style="text-align:right;">
201.5469
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-19
</td>
<td style="text-align:right;">
313.59
</td>
<td style="text-align:right;">
55.53
</td>
<td style="text-align:right;">
201.1200
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-20
</td>
<td style="text-align:right;">
318.61
</td>
<td style="text-align:right;">
55.51
</td>
<td style="text-align:right;">
201.6500
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-21
</td>
<td style="text-align:right;">
316.23
</td>
<td style="text-align:right;">
56.72
</td>
<td style="text-align:right;">
201.8600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-24
</td>
<td style="text-align:right;">
324.63
</td>
<td style="text-align:right;">
56.60
</td>
<td style="text-align:right;">
202.6100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-25
</td>
<td style="text-align:right;">
327.79
</td>
<td style="text-align:right;">
56.76
</td>
<td style="text-align:right;">
201.7100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-26
</td>
<td style="text-align:right;">
327.66
</td>
<td style="text-align:right;">
58.08
</td>
<td style="text-align:right;">
201.5800
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-27
</td>
<td style="text-align:right;">
332.75
</td>
<td style="text-align:right;">
59.77
</td>
<td style="text-align:right;">
203.2400
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-05-28
</td>
<td style="text-align:right;">
328.73
</td>
<td style="text-align:right;">
59.31
</td>
<td style="text-align:right;">
203.0400
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-01
</td>
<td style="text-align:right;">
329.13
</td>
<td style="text-align:right;">
59.65
</td>
<td style="text-align:right;">
203.2000
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-02
</td>
<td style="text-align:right;">
329.15
</td>
<td style="text-align:right;">
59.65
</td>
<td style="text-align:right;">
203.2900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-03
</td>
<td style="text-align:right;">
326.04
</td>
<td style="text-align:right;">
63.46
</td>
<td style="text-align:right;">
203.6700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-04
</td>
<td style="text-align:right;">
330.35
</td>
<td style="text-align:right;">
63.37
</td>
<td style="text-align:right;">
206.0500
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-07
</td>
<td style="text-align:right;">
336.58
</td>
<td style="text-align:right;">
63.23
</td>
<td style="text-align:right;">
203.7300
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-08
</td>
<td style="text-align:right;">
333.68
</td>
<td style="text-align:right;">
63.92
</td>
<td style="text-align:right;">
203.5900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-09
</td>
<td style="text-align:right;">
330.25
</td>
<td style="text-align:right;">
62.77
</td>
<td style="text-align:right;">
202.7400
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-10
</td>
<td style="text-align:right;">
332.46
</td>
<td style="text-align:right;">
61.34
</td>
<td style="text-align:right;">
203.1300
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-11
</td>
<td style="text-align:right;">
331.26
</td>
<td style="text-align:right;">
61.49
</td>
<td style="text-align:right;">
202.8100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-14
</td>
<td style="text-align:right;">
336.77
</td>
<td style="text-align:right;">
60.79
</td>
<td style="text-align:right;">
201.3600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-15
</td>
<td style="text-align:right;">
336.75
</td>
<td style="text-align:right;">
60.81
</td>
<td style="text-align:right;">
200.6100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-16
</td>
<td style="text-align:right;">
331.08
</td>
<td style="text-align:right;">
61.76
</td>
<td style="text-align:right;">
196.9100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-17
</td>
<td style="text-align:right;">
336.51
</td>
<td style="text-align:right;">
60.08
</td>
<td style="text-align:right;">
195.1400
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-18
</td>
<td style="text-align:right;">
329.66
</td>
<td style="text-align:right;">
58.76
</td>
<td style="text-align:right;">
191.6000
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-21
</td>
<td style="text-align:right;">
332.29
</td>
<td style="text-align:right;">
59.30
</td>
<td style="text-align:right;">
195.2100
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-22
</td>
<td style="text-align:right;">
339.03
</td>
<td style="text-align:right;">
59.24
</td>
<td style="text-align:right;">
195.1400
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-23
</td>
<td style="text-align:right;">
340.59
</td>
<td style="text-align:right;">
60.12
</td>
<td style="text-align:right;">
192.3600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-24
</td>
<td style="text-align:right;">
343.18
</td>
<td style="text-align:right;">
60.04
</td>
<td style="text-align:right;">
193.2600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-25
</td>
<td style="text-align:right;">
341.37
</td>
<td style="text-align:right;">
60.30
</td>
<td style="text-align:right;">
194.7500
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-28
</td>
<td style="text-align:right;">
355.64
</td>
<td style="text-align:right;">
58.64
</td>
<td style="text-align:right;">
196.5000
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-29
</td>
<td style="text-align:right;">
351.89
</td>
<td style="text-align:right;">
58.83
</td>
<td style="text-align:right;">
196.0300
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-06-30
</td>
<td style="text-align:right;">
347.71
</td>
<td style="text-align:right;">
59.17
</td>
<td style="text-align:right;">
198.6300
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-01
</td>
<td style="text-align:right;">
354.39
</td>
<td style="text-align:right;">
59.11
</td>
<td style="text-align:right;">
199.0900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-02
</td>
<td style="text-align:right;">
354.70
</td>
<td style="text-align:right;">
58.96
</td>
<td style="text-align:right;">
199.8900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-06
</td>
<td style="text-align:right;">
352.78
</td>
<td style="text-align:right;">
57.46
</td>
<td style="text-align:right;">
196.8900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-07
</td>
<td style="text-align:right;">
350.49
</td>
<td style="text-align:right;">
56.59
</td>
<td style="text-align:right;">
199.8600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-08
</td>
<td style="text-align:right;">
345.65
</td>
<td style="text-align:right;">
56.06
</td>
<td style="text-align:right;">
198.2700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-09
</td>
<td style="text-align:right;">
350.42
</td>
<td style="text-align:right;">
58.76
</td>
<td style="text-align:right;">
201.0000
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-12
</td>
<td style="text-align:right;">
353.16
</td>
<td style="text-align:right;">
58.97
</td>
<td style="text-align:right;">
199.9800
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-13
</td>
<td style="text-align:right;">
352.09
</td>
<td style="text-align:right;">
58.73
</td>
<td style="text-align:right;">
199.6000
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-14
</td>
<td style="text-align:right;">
347.63
</td>
<td style="text-align:right;">
58.00
</td>
<td style="text-align:right;">
202.8300
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-15
</td>
<td style="text-align:right;">
344.46
</td>
<td style="text-align:right;">
56.95
</td>
<td style="text-align:right;">
202.5900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-16
</td>
<td style="text-align:right;">
341.16
</td>
<td style="text-align:right;">
55.46
</td>
<td style="text-align:right;">
199.3700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-19
</td>
<td style="text-align:right;">
336.95
</td>
<td style="text-align:right;">
54.18
</td>
<td style="text-align:right;">
197.5600
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-20
</td>
<td style="text-align:right;">
341.66
</td>
<td style="text-align:right;">
56.15
</td>
<td style="text-align:right;">
200.8200
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-21
</td>
<td style="text-align:right;">
346.23
</td>
<td style="text-align:right;">
57.05
</td>
<td style="text-align:right;">
200.7700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-22
</td>
<td style="text-align:right;">
351.19
</td>
<td style="text-align:right;">
55.64
</td>
<td style="text-align:right;">
199.0700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-23
</td>
<td style="text-align:right;">
369.79
</td>
<td style="text-align:right;">
54.94
</td>
<td style="text-align:right;">
200.4900
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-26
</td>
<td style="text-align:right;">
372.46
</td>
<td style="text-align:right;">
55.77
</td>
<td style="text-align:right;">
201.6700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-27
</td>
<td style="text-align:right;">
367.81
</td>
<td style="text-align:right;">
55.00
</td>
<td style="text-align:right;">
200.4700
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-07-28
</td>
<td style="text-align:right;">
373.28
</td>
<td style="text-align:right;">
55.49
</td>
<td style="text-align:right;">
198.2800
</td>
</tr>
</tbody>
</table>
