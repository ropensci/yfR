## Version 1.0.2 (2022-08-21) -- bug fixes

- fixed bug in calculation of log acum returns
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
