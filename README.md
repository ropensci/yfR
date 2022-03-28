
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
In a nutshell, it provides access to daily stock prices from [Yahoo
Finance](https://finance.yahoo.com/), a vast repository with financial
data around the globe. Moreover, *yfR* allows large scales downloads of
data, using a local caching system for speeding up the process.

## Features

-   Fetchs daily/weekly/monthly/annual stock prices (and returns) from
    yahoo finance and returns a dataframe in the long format;

-   A new feature called “collection” allows for easier download of
    multiple tickers from a particular market/index;

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

## Differences from [BatchGetSymbols](https://github.com/msperlin/BatchGetSymbols)

-   All input arguments are now formatted as “snake_case” and not
    “dot.case”. For example, the argument for the first date of data
    importation in `yfR::get_yf_data` is `first_date`, and not
    `first.date` (originally from `BatchGetSymbols::BatchGetSymbols`)

-   All function have been renamed for a common API notation. For
    example, `BatchGetSymbols::BatchGetSymbols` is now
    `yfR::get_yf_data`.

-   The output is always a tibble with the price data (and not a list).
    If one wants the tibble with a summary of the importing process, it
    is available as an attribute of the output (see function
    `base::attributes`)

-   A new feature called “collection”, which allows for easy download of
    a collection of tickers. For example, you can download price data
    for all components of the SP500 by simply calling
    `yfR::yf_get_collection("SP500")`.

-   New status messages using package `cli`

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
    dissertations).

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

# set options for algorithm
my_ticker <- 'FB'
first_date <- Sys.Date() - 30
last_date <- Sys.Date()

# fetch data
df_yf <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 1 stocks | 2022-02-26 --> 2022-03-28 (30 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for FB
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 20 valid rows (2022-02-28 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Got it!
#> ℹ Binding price data

# output is a tibble with data
str(df_yf)
#> grouped_df [20 × 10] (S3: grouped_df/tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:20] "FB" "FB" "FB" "FB" ...
#>  $ ref_date           : Date[1:20], format: "2022-02-28" "2022-03-01" ...
#>  $ price_open         : num [1:20] 208 210 205 209 202 ...
#>  $ price_high         : num [1:20] 213 212 209 209 206 ...
#>  $ price_low          : num [1:20] 207 202 202 201 199 ...
#>  $ price_close        : num [1:20] 211 203 208 203 200 ...
#>  $ volume             : num [1:20] 34239800 27094900 29452100 27263500 32130900 ...
#>  $ price_adjusted     : num [1:20] 211 203 208 203 200 ...
#>  $ ret_adjusted_prices: num [1:20] NA -0.0357 0.0227 -0.0247 -0.0143 ...
#>  $ ret_closing_prices : num [1:20] NA -0.0357 0.0227 -0.0247 -0.0143 ...
#>  - attr(*, "groups")= tibble [20 × 3] (S3: tbl_df/tbl/data.frame)
#>   ..$ ref_date: Date[1:20], format: "2022-02-28" "2022-03-01" ...
#>   ..$ ticker  : chr [1:20] "FB" "FB" "FB" "FB" ...
#>   ..$ .rows   : list<int> [1:20] 
#>   .. ..$ : int 1
#>   .. ..$ : int 2
#>   .. ..$ : int 3
#>   .. ..$ : int 4
#>   .. ..$ : int 5
#>   .. ..$ : int 6
#>   .. ..$ : int 7
#>   .. ..$ : int 8
#>   .. ..$ : int 9
#>   .. ..$ : int 10
#>   .. ..$ : int 11
#>   .. ..$ : int 12
#>   .. ..$ : int 13
#>   .. ..$ : int 14
#>   .. ..$ : int 15
#>   .. ..$ : int 16
#>   .. ..$ : int 17
#>   .. ..$ : int 18
#>   .. ..$ : int 19
#>   .. ..$ : int 20
#>   .. ..@ ptype: int(0) 
#>   ..- attr(*, ".drop")= logi TRUE
#>  - attr(*, "df_control")= tibble [1 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr "FB"
#>   ..$ dl_status           : chr "OK"
#>   ..$ n_rows              : int 20
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
#> ── Running yfR for 3 stocks | 2021-12-18 --> 2022-03-28 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✓    - found cache file (2022-02-28 --> 2022-03-25)
#> !    - need new data (cache doesnt match query)
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Well done msperlin!
#> ℹ (2/3) Fetching data for GM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- You got it msperlin!
#> ℹ (3/3) Fetching data for MMM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Good job msperlin!
#> ℹ Binding price data

str(df_yf_multiple)

p <- ggplot(df_yf_multiple, aes(x = ref_date, y = price_adjusted,
                       color = ticker)) + 
  geom_line()

p
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

    #> grouped_df [201 × 10] (S3: grouped_df/tbl_df/tbl/data.frame)
    #>  $ ticker             : chr [1:201] "FB" "FB" "FB" "FB" ...
    #>  $ ref_date           : Date[1:201], format: "2021-12-20" "2021-12-21" ...
    #>  $ price_open         : num [1:201] 330 326 334 330 339 ...
    #>  $ price_high         : num [1:201] 330 336 335 337 348 ...
    #>  $ price_low          : num [1:201] 323 324 328 328 338 ...
    #>  $ price_close        : num [1:201] 325 334 330 335 346 ...
    #>  $ volume             : num [1:201] 17901800 16116800 16764600 13987700 17795000 ...
    #>  $ price_adjusted     : num [1:201] 325 334 330 335 346 ...
    #>  $ ret_adjusted_prices: num [1:201] NA 0.0269 -0.0112 0.0145 0.0326 ...
    #>  $ ret_closing_prices : num [1:201] NA 0.0269 -0.0112 0.0145 0.0326 ...
    #>  - attr(*, "groups")= tibble [201 × 3] (S3: tbl_df/tbl/data.frame)
    #>   ..$ ref_date: Date[1:201], format: "2021-12-20" "2021-12-20" ...
    #>   ..$ ticker  : chr [1:201] "FB" "GM" "MMM" "FB" ...
    #>   ..$ .rows   : list<int> [1:201] 
    #>   .. ..$ : int 1
    #>   .. ..$ : int 68
    #>   .. ..$ : int 135
    #>   .. ..$ : int 2
    #>   .. ..$ : int 69
    #>   .. ..$ : int 136
    #>   .. ..$ : int 3
    #>   .. ..$ : int 70
    #>   .. ..$ : int 137
    #>   .. ..$ : int 4
    #>   .. ..$ : int 71
    #>   .. ..$ : int 138
    #>   .. ..$ : int 5
    #>   .. ..$ : int 72
    #>   .. ..$ : int 139
    #>   .. ..$ : int 6
    #>   .. ..$ : int 73
    #>   .. ..$ : int 140
    #>   .. ..$ : int 7
    #>   .. ..$ : int 74
    #>   .. ..$ : int 141
    #>   .. ..$ : int 8
    #>   .. ..$ : int 75
    #>   .. ..$ : int 142
    #>   .. ..$ : int 9
    #>   .. ..$ : int 76
    #>   .. ..$ : int 143
    #>   .. ..$ : int 10
    #>   .. ..$ : int 77
    #>   .. ..$ : int 144
    #>   .. ..$ : int 11
    #>   .. ..$ : int 78
    #>   .. ..$ : int 145
    #>   .. ..$ : int 12
    #>   .. ..$ : int 79
    #>   .. ..$ : int 146
    #>   .. ..$ : int 13
    #>   .. ..$ : int 80
    #>   .. ..$ : int 147
    #>   .. ..$ : int 14
    #>   .. ..$ : int 81
    #>   .. ..$ : int 148
    #>   .. ..$ : int 15
    #>   .. ..$ : int 82
    #>   .. ..$ : int 149
    #>   .. ..$ : int 16
    #>   .. ..$ : int 83
    #>   .. ..$ : int 150
    #>   .. ..$ : int 17
    #>   .. ..$ : int 84
    #>   .. ..$ : int 151
    #>   .. ..$ : int 18
    #>   .. ..$ : int 85
    #>   .. ..$ : int 152
    #>   .. ..$ : int 19
    #>   .. ..$ : int 86
    #>   .. ..$ : int 153
    #>   .. ..$ : int 20
    #>   .. ..$ : int 87
    #>   .. ..$ : int 154
    #>   .. ..$ : int 21
    #>   .. ..$ : int 88
    #>   .. ..$ : int 155
    #>   .. ..$ : int 22
    #>   .. ..$ : int 89
    #>   .. ..$ : int 156
    #>   .. ..$ : int 23
    #>   .. ..$ : int 90
    #>   .. ..$ : int 157
    #>   .. ..$ : int 24
    #>   .. ..$ : int 91
    #>   .. ..$ : int 158
    #>   .. ..$ : int 25
    #>   .. ..$ : int 92
    #>   .. ..$ : int 159
    #>   .. ..$ : int 26
    #>   .. ..$ : int 93
    #>   .. ..$ : int 160
    #>   .. ..$ : int 27
    #>   .. ..$ : int 94
    #>   .. ..$ : int 161
    #>   .. ..$ : int 28
    #>   .. ..$ : int 95
    #>   .. ..$ : int 162
    #>   .. ..$ : int 29
    #>   .. ..$ : int 96
    #>   .. ..$ : int 163
    #>   .. ..$ : int 30
    #>   .. ..$ : int 97
    #>   .. ..$ : int 164
    #>   .. ..$ : int 31
    #>   .. ..$ : int 98
    #>   .. ..$ : int 165
    #>   .. ..$ : int 32
    #>   .. ..$ : int 99
    #>   .. ..$ : int 166
    #>   .. ..$ : int 33
    #>   .. ..$ : int 100
    #>   .. ..$ : int 167
    #>   .. .. [list output truncated]
    #>   .. ..@ ptype: int(0) 
    #>   ..- attr(*, ".drop")= logi TRUE
    #>  - attr(*, "df_control")= tibble [3 × 5] (S3: tbl_df/tbl/data.frame)
    #>   ..$ ticker              : chr [1:3] "FB" "GM" "MMM"
    #>   ..$ dl_status           : chr [1:3] "OK" "OK" "OK"
    #>   ..$ n_rows              : int [1:3] 67 67 67
    #>   ..$ perc_benchmark_dates: num [1:3] 1 1 1
    #>   ..$ threshold_decision  : chr [1:3] "KEEP" "KEEP" "KEEP"

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
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-03-28 (4469 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 3079 valid rows (2010-01-04 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- All OK!
#> ℹ Binding price data
  
  
df_weekly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'weekly') |>
  mutate(freq = 'weekly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-03-28 (4469 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2022-03-25)
#> ✓    - got 3079 valid rows (2010-01-04 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- You got it msperlin!
#> ℹ Binding price data

df_monthly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'monthly') |>
  mutate(freq = 'monthly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-03-28 (4469 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2022-03-25)
#> ✓    - got 3079 valid rows (2010-01-04 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Nice!
#> ℹ Binding price data

df_yearly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'yearly') |>
  mutate(freq = 'yearly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2022-03-28 (4469 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2022-03-25)
#> ✓    - got 3079 valid rows (2010-01-04 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- All OK!
#> ℹ Binding price data

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
#> ── Running yfR for 3 stocks | 2021-12-18 --> 2022-03-28 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✓    - found cache file (2021-12-20 --> 2022-03-25)
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Looking good!
#> ℹ (2/3) Fetching data for GM
#> ✓    - found cache file (2021-12-20 --> 2022-03-25)
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- All OK!
#> ℹ (3/3) Fetching data for MMM
#> ✓    - found cache file (2021-12-20 --> 2022-03-25)
#> ✓    - got 67 valid rows (2021-12-20 --> 2022-03-25)
#> ✓    - got 100% of valid prices -- Time for some tea?
#> ℹ Binding price data

l_wide <- yf_converto_to_wide(df_yf_multiple)

prices_wide <- l_wide$price_adjusted

knitr::kable(head(prices_wide)) 
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
2021-12-20
</td>
<td style="text-align:right;">
325.45
</td>
<td style="text-align:right;">
54.04
</td>
<td style="text-align:right;">
170.9872
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-12-21
</td>
<td style="text-align:right;">
334.20
</td>
<td style="text-align:right;">
54.79
</td>
<td style="text-align:right;">
171.2645
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-12-22
</td>
<td style="text-align:right;">
330.45
</td>
<td style="text-align:right;">
56.08
</td>
<td style="text-align:right;">
170.9872
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-12-23
</td>
<td style="text-align:right;">
335.24
</td>
<td style="text-align:right;">
56.91
</td>
<td style="text-align:right;">
173.2948
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-12-27
</td>
<td style="text-align:right;">
346.18
</td>
<td style="text-align:right;">
57.43
</td>
<td style="text-align:right;">
175.0083
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-12-28
</td>
<td style="text-align:right;">
346.22
</td>
<td style="text-align:right;">
57.11
</td>
<td style="text-align:right;">
175.9393
</td>
</tr>
</tbody>
</table>
