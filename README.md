## Motivation

[![](https://cranlogs.r-pkg.org/badges/BatchGetSymbols)](https://CRAN.R-project.org/package=BatchGetSymbols)

`yf` is the second and backwards-incompatible version of [BatchGetSymbols](https://CRAN.R-project.org/package=BatchGetSymbols), a R package for large-scale download of financial data from Yahoo Finance. Based on a set of tickers and date ranges, the package will download and organize the financial data in the tidy/long format.


## Changes from `BatchGetSymbols`

- New and more intuitive function names: BatchGetSymbols() -->  get_yf_data()
- Use of collections for fetching large scale data (function `get_collection()`)
- No more dependency of quantmod:getSymbols
- Better status bars
- Better handling of invalid data


## Warnings

- Yahoo finance data is far from perfect or reliable, specially for individual stocks. In my experience, using it for research code with stock **indices** is fine and I can match it with other data sources. But, adjusted stock prices for **individual assets** is messy as stock events such as splits or dividends are not properly registered. I was never able to match it with other data sources. My advice is to never use the data of individual stocks in production. 

- Since version 2.6, the cache system is session-persistent by default, meaning that whenever you restart your R session, you lose all your cached data. This is a safety feature for mismatching prices due to corporate events.

## Main features:

- Organizes data in a tabular/long or wide format, returning prices and returns (arithmetic or logarithmic)
- A session-persistent cache system was implemented. This means that the data is saved locally and only missing portions of the data are downloaded, if needed.
- All dates are compared to a benchmark ticker such as SP500 and, whenever an individual asset does not have a sufficient number of dates, the software drops it from the output. This means you can choose to ignore tickers with high number of missing dates.
- Allows the choice for the wide format, with tickers as columns
- Users can choose the frequency of the resulting dataset (daily, weekly, monthly, yearly)
- Option for parallel computing, speeding up the data importation process



## Installation

```
# CRAN (not yet available)
#install.packages('yf')

# Github (dev version)
devtools::install_github('msperlin/yf')
```

## A simple example

See [vignette](https://CRAN.R-project.org/package=yf).
