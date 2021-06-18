
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
#> ✓    - got 95% of valid prices -- Good stuff!

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
library(ggplot2)

my_ticker <- c('FB', 'GM', 'MMM')
first_date <- Sys.Date() - 100
last_date <- Sys.Date()

df_yf_multiple <- yf_get_data(tickers = my_ticker, 
                     first_date = first_date,
                     last_date = last_date)
#> 
#> ── Running yfR for 3 stocks | 2021-03-10 --> 2021-06-18 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Good stuff!
#> ℹ (2/3) Fetching data for GM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Looking good!
#> ℹ (3/3) Fetching data for MMM
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Good job msperlin!

str(df_yf_multiple)
#> tibble [207 × 10] (S3: tbl_df/tbl/data.frame)
#>  $ ticker             : chr [1:207] "FB" "FB" "FB" "FB" ...
#>  $ ref_date           : Date[1:207], format: "2021-03-10" "2021-03-11" ...
#>  $ price_open         : num [1:207] 269 268 269 269 276 ...
#>  $ price_high         : num [1:207] 269 278 270 276 282 ...
#>  $ price_low          : num [1:207] 263 268 264 268 275 ...
#>  $ price_close        : num [1:207] 265 274 268 274 279 ...
#>  $ volume             : num [1:207] 14210300 21834000 20600200 16844800 22437700 ...
#>  $ price_adjusted     : num [1:207] 265 274 268 274 279 ...
#>  $ ret_adjusted_prices: num [1:207] NA 0.0339 -0.02 0.0199 0.0202 ...
#>  $ ret_closing_prices : num [1:207] NA 0.0339 -0.02 0.0199 0.0202 ...
#>  - attr(*, "df_control")= tibble [3 × 5] (S3: tbl_df/tbl/data.frame)
#>   ..$ ticker              : chr [1:3] "FB" "GM" "MMM"
#>   ..$ dl_status           : chr [1:3] "OK" "OK" "OK"
#>   ..$ n_rows              : int [1:3] 69 69 69
#>   ..$ perc_benchmark_dates: num [1:3] 1 1 1
#>   ..$ threshold_decision  : chr [1:3] "KEEP" "KEEP" "KEEP"

p <- ggplot(df_yf_multiple, aes(x = ref_date, y = price_adjusted,
                       color = ticker)) + 
  geom_line()

p
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

### Fetching collections of prices

Collections are just a bundle of ticker pre-organized in the package.
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
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-06-18 (4186 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> !    - not cached
#> ✓    - cache saved successfully
#> ✓    - got 2883 valid rows (2010-01-04 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- You got it msperlin!
  
  
df_weekly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'weekly') |>
  mutate(freq = 'weekly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-06-18 (4186 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-06-16)
#> ✓    - got 2883 valid rows (2010-01-04 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Time for some tea?

df_monthly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'monthly') |>
  mutate(freq = 'monthly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-06-18 (4186 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-06-16)
#> ✓    - got 2883 valid rows (2010-01-04 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- All OK!

df_yearly <- yf_get_data(tickers = my_ticker, 
                         first_date, last_date, 
                         freq_data = 'yearly') |>
  mutate(freq = 'yearly')
#> 
#> ── Running yfR for 1 stocks | 2010-01-01 --> 2021-06-18 (4186 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/1) Fetching data for GE
#> ✓    - found cache file (2010-01-04 --> 2021-06-16)
#> ✓    - got 2883 valid rows (2010-01-04 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Well done msperlin!

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
#> ── Running yfR for 3 stocks | 2021-03-10 --> 2021-06-18 (100 days) ──
#> 
#> ℹ Downloading data for benchmark ticker ^GSPC
#> ℹ (1/3) Fetching data for FB
#> ✓    - found cache file (2021-03-10 --> 2021-06-16)
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Got it!
#> ℹ (2/3) Fetching data for GM
#> ✓    - found cache file (2021-03-10 --> 2021-06-16)
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- You got it msperlin!
#> ℹ (3/3) Fetching data for MMM
#> ✓    - found cache file (2021-03-10 --> 2021-06-16)
#> ✓    - got 69 valid rows (2021-03-10 --> 2021-06-16)
#> ✓    - got 100% of valid prices -- Got it!

l_wide <- yf_converto_to_wide(df_yf_multiple)

prices_wide <- l_wide$price_adjusted

knitr::kable(prices_wide)
```

<table>
<thead>
<tr>
<th style="text-align:left;">
ref\_date
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
2021-03-10
</td>
<td style="text-align:right;">
264.90
</td>
<td style="text-align:right;">
56.83
</td>
<td style="text-align:right;">
183.1621
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-11
</td>
<td style="text-align:right;">
273.88
</td>
<td style="text-align:right;">
56.33
</td>
<td style="text-align:right;">
183.2217
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-12
</td>
<td style="text-align:right;">
268.40
</td>
<td style="text-align:right;">
59.26
</td>
<td style="text-align:right;">
183.5692
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-15
</td>
<td style="text-align:right;">
273.75
</td>
<td style="text-align:right;">
57.94
</td>
<td style="text-align:right;">
188.0958
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-16
</td>
<td style="text-align:right;">
279.28
</td>
<td style="text-align:right;">
57.12
</td>
<td style="text-align:right;">
185.4851
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-17
</td>
<td style="text-align:right;">
284.01
</td>
<td style="text-align:right;">
60.05
</td>
<td style="text-align:right;">
186.9245
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-18
</td>
<td style="text-align:right;">
278.62
</td>
<td style="text-align:right;">
59.27
</td>
<td style="text-align:right;">
189.6047
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-19
</td>
<td style="text-align:right;">
290.11
</td>
<td style="text-align:right;">
59.82
</td>
<td style="text-align:right;">
187.3315
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-22
</td>
<td style="text-align:right;">
293.54
</td>
<td style="text-align:right;">
58.10
</td>
<td style="text-align:right;">
188.0859
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-23
</td>
<td style="text-align:right;">
290.63
</td>
<td style="text-align:right;">
56.16
</td>
<td style="text-align:right;">
186.9542
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-24
</td>
<td style="text-align:right;">
282.14
</td>
<td style="text-align:right;">
55.81
</td>
<td style="text-align:right;">
189.2970
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-25
</td>
<td style="text-align:right;">
278.74
</td>
<td style="text-align:right;">
56.60
</td>
<td style="text-align:right;">
191.6894
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-26
</td>
<td style="text-align:right;">
283.02
</td>
<td style="text-align:right;">
56.52
</td>
<td style="text-align:right;">
193.4564
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-29
</td>
<td style="text-align:right;">
290.82
</td>
<td style="text-align:right;">
55.94
</td>
<td style="text-align:right;">
194.3101
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-30
</td>
<td style="text-align:right;">
288.00
</td>
<td style="text-align:right;">
58.51
</td>
<td style="text-align:right;">
193.2182
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-03-31
</td>
<td style="text-align:right;">
294.53
</td>
<td style="text-align:right;">
57.46
</td>
<td style="text-align:right;">
191.2725
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-01
</td>
<td style="text-align:right;">
298.66
</td>
<td style="text-align:right;">
57.80
</td>
<td style="text-align:right;">
191.2923
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-05
</td>
<td style="text-align:right;">
308.91
</td>
<td style="text-align:right;">
61.04
</td>
<td style="text-align:right;">
193.5457
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-06
</td>
<td style="text-align:right;">
306.26
</td>
<td style="text-align:right;">
61.94
</td>
<td style="text-align:right;">
193.4167
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-07
</td>
<td style="text-align:right;">
313.09
</td>
<td style="text-align:right;">
60.83
</td>
<td style="text-align:right;">
193.5259
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-08
</td>
<td style="text-align:right;">
313.02
</td>
<td style="text-align:right;">
60.09
</td>
<td style="text-align:right;">
194.2903
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-09
</td>
<td style="text-align:right;">
312.46
</td>
<td style="text-align:right;">
60.16
</td>
<td style="text-align:right;">
196.5536
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-12
</td>
<td style="text-align:right;">
311.54
</td>
<td style="text-align:right;">
59.66
</td>
<td style="text-align:right;">
196.3848
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-13
</td>
<td style="text-align:right;">
309.76
</td>
<td style="text-align:right;">
58.49
</td>
<td style="text-align:right;">
195.0348
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-14
</td>
<td style="text-align:right;">
302.82
</td>
<td style="text-align:right;">
58.48
</td>
<td style="text-align:right;">
195.3127
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-15
</td>
<td style="text-align:right;">
307.82
</td>
<td style="text-align:right;">
58.61
</td>
<td style="text-align:right;">
196.0374
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-16
</td>
<td style="text-align:right;">
306.18
</td>
<td style="text-align:right;">
58.71
</td>
<td style="text-align:right;">
197.1294
</td>
</tr>
<tr>
<td style="text-align:left;">
2021-04-19
</td>
<td style="text-align:right;">
302.24
</td>
<td style="text-align:right;">
57.88
</td>
<td style="text-align:right;">
197.1393
</td>
</tr>
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
</tbody>
</table>
