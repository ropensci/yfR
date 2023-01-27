## Version 1.0.7 (2023-01-27) -- extra function yf_live_prices()

- added function yf_live_prices() (see this [pr](https://github.com/ropensci/yfR/pull/24))

## Version 1.0.6 (2023-01-06) -- bug fixes and CRAN submission

- fix for when user is requesting one trading day. Now it gives a warning and not an error -- [fixes #23](https://github.com/ropensci/yfR/issues/23)
- added new market index DOW (^DJI)
- now using roxygen version 7.2.3

## Version 1.0.5 (2022-11-23) -- bug fixes

- now using tidyselect::all_of() (fixes [issue #22](https://github.com/ropensci/yfR/issues/22))

## Version 1.0.4 (2022-11-15) -- bug fixes

- switched curl::has_internet by pingr::is_online() -- the first doesn't seem to work on restricted networks. Fixes [#20](https://github.com/ropensci/yfR/issues/20)
- fix for when user is requesting one trading day -- fixes #19

## Version 1.0.3 (2022-10-20) -- bug fixes

- fixed bug on number of files at cache folder

## Version 1.0.2 (2022-08-21) -- bug fixes

- changed FB ticker to META
- fixed bug in calculation of log accumulated returns
- fixed bug in order of tickers (now it makes sure the ticker symbol is sorted)

## Version 1.0.1 (2022-08-15) -- bug fixes

- fixed bug with FB ticker (change to TSLA)

## Version 1.0.0 (2022-06-22) -- CRAN SUBMISSION

- many pkg changes after [ropensci approval](https://github.com/ropensci/software-review/issues/523)
- github repo is now under <https://github.com/ropensci/yfR>
- changed all \dontrun by \donttest (as suggested by CRAN team)
- used n_cores = 2 (as suggested by CRAN)

## Version 0.0.5 (2022-06-07)

- Many changes for ropensci

## Version 0.0.3 (2022-05-03)

- Added cumulative return at output

## Version 0.0.2 (2022-05-02)

- Added warning message for parallel option (yahoo finance has just set a api limit)
- Fixed typos in readme.md

## Version 0.0.1 (2022-03-28)

- First version, ported from [BatchGetSymbols](https://github.com/msperlin/BatchGetSymbols)
