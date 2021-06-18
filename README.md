
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://cranlogs.r-pkg.org/badges/yfR)](https://CRAN.R-project.org/yfR)

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

# Motivation

`yfR` is the second and backwards-incompatible version of
[BatchGetSymbols](https://CRAN.R-project.org/package=BatchGetSymbols), a
R package for large-scale download of financial data from Yahoo Finance.
It make it easier to fetch tidy data of stock prices from the
repository.

## Features

-   Fetchs daily/weekly/monthly/annual stock prices and returns from
    yahoo finance;
-   Organizes data in a tabular/long or wide format, returning prices
    and returns (arithmetic or logarithmic)
-   A session-persistent smart cache system is available by default.
    This means that the YF data is saved locally and only missing
    portions are downloaded, if needed.
-   All dates are compared to a benchmark ticker such as SP500 and,
    whenever an individual asset does not have a sufficient number of
    dates, the software drops it from the output. This means you can
    choose to ignore tickers with high number of missing dates.
-   A customized function called `yf_convert_to_wide()` can transform
    the long table into a wide format (tickers as columns).
-   Users can choose the frequency of the resulting dataset (daily,
    weekly, monthly, yearly)
-   Parallel computing is available, speeding up the data importation
    process

## Warnings

-   Yahoo finance data is far from perfect or reliable, specially for
    individual stocks. In my experience, using it for research code with
    stock **indices** is fine and I can match it with other data
    sources. But, adjusted stock prices for **individual assets** is
    messy as stock events such as splits or dividends are not properly
    registered. I was never able to match it with other data sources,
    specially for long time periods with lots of corporate events. My
    advice is to never use the data of individual stocks in production.

-   Since version 2.6 of BatchGetSymbols, from which this package was
    based, the cache system is session-persistent by default, meaning
    that whenever you restart your R session, you lose all your cached
    data. This is a safety feature for mismatching prices due to
    corporate events.

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

my_ticker <- '^BVSP'
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

df_yf <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 1 stocks | 2021-05-19 --> 2021-06-18 (30 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for ^BVSP
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 20 valid rows (2021-05-19 --> 2021-06-16)
#> ✓    - got 95% of valid prices -- You got it msperlin!

str(df_yf)
#> tibble [20 × 10] (S3: tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:20] "^BVSP" "^BVSP" "^BVSP" "^BVSP" ...
#>  $ ref_date           : Date[1:20], format: "2021-05-19" "2021-05-20" ...
#>  $ price_open         : num [1:20] 122976 122636 122701 122592 124032 ...
#>  $ price_high         : num [1:20] 123013 122734 122799 124167 124696 ...
#>  $ price_low          : num [1:20] 121595 122136 121760 122526 122701 ...
#>  $ price_close        : num [1:20] 122636 122701 122592 124032 122988 ...
#>  $ volume             : num [1:20] 8825300 7906400 9493600 8186300 8914500 ...
#>  $ price_adjusted     : num [1:20] 122636 122701 122592 124032 122988 ...
#>  $ ret_adjusted_prices: num [1:20] NA 0.00053 -0.000888 0.011746 -0.008417 ...
#>  $ ret_closing_prices : num [1:20] NA 0.00053 -0.000888 0.011746 -0.008417 ...
#>  - attr(*, "df_control")= tibble [1 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr "^BVSP"
#>   ..$ dl_status           : chr "OK"
#>   ..$ n_rows              : int 20
#>   ..$ perc_benchmark_dates: num 0.95
#>   ..$ threshold_decision  : chr "KEEP"
```

### Fetching many stock prices

``` r
library(yfR)

my_ticker <- c('FB', '^BVSP', 'MMM')
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

df_yf <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2021-05-19 --> 2021-06-18 (30 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 20 valid rows (2021-05-19 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Got it!
#> ℹ (2/3) Fetching data for ^BVSP
#> ✓    - found cache file (2021-05-19 --> 2021-06-16)
#> ✓    - got 20 valid rows (2021-05-19 --> 2021-06-16)
#> ✓    - got 95% of valid prices -- You got it msperlin!
#> ℹ (3/3) Fetching data for MMM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 20 valid rows (2021-05-19 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Mas bah tche, que coisa linda!

str(df_yf)
#> tibble [60 × 10] (S3: tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:60] "FB" "FB" "FB" "FB" ...
#>  $ ref_date           : Date[1:60], format: "2021-05-19" "2021-05-20" ...
#>  $ price_open         : num [1:60] 304 314 319 318 327 ...
#>  $ price_high         : num [1:60] 315 319 320 326 329 ...
#>  $ price_low          : num [1:60] 304 313 316 318 325 ...
#>  $ price_close        : num [1:60] 314 319 316 325 328 ...
#>  $ volume             : num [1:60] 19106200 17320200 13600900 16445400 16437000 ...
#>  $ price_adjusted     : num [1:60] 314 319 316 325 328 ...
#>  $ ret_adjusted_prices: num [1:60] NA 0.01601 -0.00747 0.02656 0.00973 ...
#>  $ ret_closing_prices : num [1:60] NA 0.01601 -0.00747 0.02656 0.00973 ...
#>  - attr(*, "df_control")= tibble [3 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr [1:3] "FB" "^BVSP" "MMM"
#>   ..$ dl_status           : chr [1:3] "OK" "OK" "OK"
#>   ..$ n_rows              : int [1:3] 20 20 20
#>   ..$ perc_benchmark_dates: num [1:3] 1 0.95 1
#>   ..$ threshold_decision  : chr [1:3] "KEEP" "KEEP" "KEEP"
```

### Fetching collections of prices

Collections are just a bundle of ticker pre-organized in the package.
For example, collection `SP500` represents the current composition of
the Ibovspa index.

``` r
library(yfR)

df_yf <- yf_get_collection("SP500")

str(df_yf)
```
