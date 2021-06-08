#' Function to download financial data
#'
#' This function downloads financial data from Yahoo Finance. Based on a set of tickers and a time period, the function will download the data for each ticker and return a report of the process, along with the actual data in the long dataframe format.
#' The main advantage of the function is that it automatically recognizes the source of the dataset from the ticker and structures the resulting data from different sources in the long format.
#' A caching system is also available, making it very fast.
#'
#' @section Warning:
#'
#' Do notice that since 2019, adjusted prices are no longer available from google finance.
#' When using this source, the function will output NA values for this column.
#'
#' Also, be aware that when using cache system in a local folder (and not the default tempdir()), the aggregate prices series might not match if
#' a split or dividends event happens in between cache files.
#'
#' @param tickers A vector of tickers. If not sure whether the ticker is available, check the websites of google and yahoo finance. The source for downloading
#'  the data can either be Google or Yahoo. The function automatically selects the source webpage based on the input ticker.
#' @param first_date The first date to download data (date or char as YYYY-MM-DD)
#' @param last_date The last date to download data (date or char as YYYY-MM-DD)
#' @param bench_ticker The ticker of the benchmark asset used to compare dates. My suggestion is to use the main stock index of the market from where the data is coming from (default = ^GSPC (SP500, US market))
#' @param type_return Type of price return to calculate: 'arit' (default) - aritmetic, 'log' - log returns.
#' @param freq_data Frequency of financial data ('daily', 'weekly', 'monthly', 'yearly')
#' @param how_to_aggregate Defines whether to aggregate the data using the first observations of the aggregating period or last ('first', 'last').
#'  For example, if freq_data = 'yearly' and how_to_aggregate = 'last', the last available day of the year will be used for all
#'  aggregated values such as price.adjusted.
#' @param thresh_bad_data A percentage threshold for defining bad data. The dates of the benchmark ticker are compared to each asset. If the percentage of non-missing dates
#'  with respect to the benchmark ticker is lower than thresh_bad_data, the function will ignore the asset (default = 0.75)
#' @param do_complete_data Return a complete/balanced dataset? If TRUE, all missing pairs of ticker-date will be replaced by NA or closest price (see input do_fill_missing_prices). Default = FALSE.
#' @param do_fill_missing_prices Finds all missing prices and replaces them by their closest price with preference for the previous price. This ensures a balanced dataset for all assets, without any NA. Default = TRUE.
#' @param do_cache Use cache system? (default = TRUE)
#' @param cache_folder Where to save cache files? (default = file.path(tempdir(), 'BGS_Cache') )
#' @param do_parallel Flag for using parallel or not (default = FALSE). Before using parallel, make sure you call function future::plan() first.
#' @param be_quiet Logical for printing statements (default = FALSE)
#' @return A list with the following items: \describe{
#' \item{df.control }{A dataframe containing the results of the download process for each asset}
#' \item{df.tickers}{A dataframe with the financial data for all valid tickers} }
#' @export
#' @import dplyr
#'
#' @seealso \link[quantmod]{getSymbols}
#'
#' @examples
#' tickers <- c('FB','MMM')
#'
#' first_date <- Sys.Date()-30
#' last_date <- Sys.Date()
#'
#' l.out <- yf_get_data(tickers = tickers,
#'                      first_date = first_date,
#'                      last_date = last_date, do_cache=FALSE)
#'
#' print(l.out$df.control)
#' print(l.out$df.tickers)
yf_get_data <- function(tickers,
                            first_date = Sys.Date()-30,
                            last_date = Sys.Date(),
                            thresh_bad_data = 0.75,
                            bench_ticker = '^GSPC',
                            type_return = 'arit',
                            freq_data = 'daily',
                            how_to_aggregate = 'last',
                            do_complete_data = FALSE,
                            do_fill_missing_prices = TRUE,
                            do_cache = TRUE,
                            cache_folder = yf_get_default_cache_folder(),
                            do_parallel = FALSE,
                            be_quiet = FALSE) {

  # check for internet
  if (!curl::has_internet()) {
    stop('Cant find an active internet connection...')
  }

  # check cache folder
  if ( (do_cache)&(!dir.exists(cache_folder))) dir.create(cache_folder, recursive = TRUE)

  # check options
  possible_values <- c('arit', 'log')
  if (!any(type_return %in% possible_values)) {
    stop(paste0('Input type.ret should be one of:\n\n', paste0(possible_values, collapse = '\n')))
  }

  possible_values <- c('first', 'last')
  if (!any(how_to_aggregate %in% possible_values)) {
    stop(paste0('Input how_to_aggregate should be one of:\n\n', paste0(possible_values, collapse = '\n')))
  }

  # check for NA
  if (any(is.na(tickers))) {
    my_msg <- paste0('Found NA value in ticker vector.',
                     'You need to remove it before running BatchGetSymbols.')
    stop(my_msg)
  }

  possible_values <- c('daily', 'weekly', 'monthly', 'yearly')
  if (!any(freq_data %in% possible_values)) {
    stop(paste0('Input freq_data should be one of:\n\n', paste0(possible_values, collapse = '\n')))
  }

  # check date class
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  if (class(first_date) != 'Date') {
    stop('ERROR: Input first_date should be of class Date')
  }

  if (class(last_date) != 'Date') {
    stop('ERROR: Input first_date should be of class Date')
  }

  if (last_date<=first_date){
    stop('The last_date is lower (less recent) or equal to first_date. Check your dates!')
  }

  # check tickers
  if (!is.null(tickers)){
    tickers <- as.character(tickers)

    if (class(tickers)!='character'){
      stop('The input tickers should be a character object.')
    }
  }

  # check threshold
  if ( (thresh_bad_data<0)|(thresh_bad_data>1)){
    stop('Input thresh_bad_data should be a proportion between 0 and 1')
  }

  # build tickers_src (google tickers have : in their name)
  tickers_src <- ifelse(stringr::str_detect(tickers,':'),'google','yahoo')

  if (any(tickers_src == 'google')) {
    my_msg <- 'Google is no longer providing price data.
    You should be using tickers from YFinance'
    stop(my_msg)
  }

  # fix for dates with google finance data
  # details: http://stackoverflow.com/questions/20472376/quantmod-empty-dates-in-getsymbols-from-google

  if(any(tickers_src=='google')){
    suppressWarnings({
      invisible(Sys.setlocale("LC_MESSAGES", "C"))
      invisible(Sys.setlocale("LC_TIME", "C"))
    })
  }

  # disable dplyr group message
  options(dplyr.summarise.inform = FALSE)

  # first screen msgs

  if (!be_quiet) {
    message('\nRunning BatchGetSymbols for:', appendLF = FALSE )
    message('\n   tickers =', paste0(tickers, collapse = ', '), appendLF = FALSE )
    message('\n   Downloading data for benchmark ticker', appendLF = FALSE )
  }

  # detect if bench_src is google or yahoo (google tickers have : in their name)
  bench_src <- ifelse(stringr::str_detect(bench_ticker,':'),'google','yahoo')

  df.bench <- myGetSymbols(ticker = bench_ticker,
                           i.ticker = 1,
                           length.tickers = 1,
                           src = bench_src,
                           first_date = first_date,
                           last_date = last_date,
                           do_cache = do_cache,
                           cache_folder = cache_folder,
                           be_quiet = be_quiet)

  # run fetching function for all tickers

  l.args <- list(ticker = tickers,
                 i.ticker = seq_along(tickers),
                 length.tickers = length(tickers),
                 src = tickers_src,
                 first_date = first_date,
                 last_date = last_date,
                 do_cache = do_cache,
                 cache_folder = cache_folder,
                 df.bench = rep(list(df.bench), length(tickers)),
                 thresh_bad_data = thresh_bad_data,
                 be_quiet =  be_quiet)

  if (!do_parallel) {

    my.l <- purrr::pmap(.l = l.args,
                        .f = myGetSymbols)

  } else {

    # find number of used cores
    formals.parallel <- formals(future::plan())
    used.workers <- formals.parallel$workers

    available.cores <- future::availableCores()

    if (!be_quiet) {
      message(paste0('\nRunning parallel BatchGetSymbols with ', used.workers, ' cores (',
                     available.cores, ' available)'), appendLF = FALSE )
      message('\n\n', appendLF = FALSE )
    }


    # test if plan() was called
    msg <- utils::capture.output(future::plan())

    flag <- stringr::str_detect(msg[1], 'sequential')

    if (flag) {
      stop(paste0('When using do_parallel = TRUE, you need to call future::plan() to configure your parallel settings. \n',
                  'A suggestion, write the following lines:\n\n',
                  'future::plan(future::multisession, workers = floor(parallel::detectCores()/2))',
                  '\n\n',
                  'The last line should be placed just before calling BatchGetSymbols. ',
                  'Notice it will use half of your available cores so that your OS has some room to breathe.'))
    }


    my.l <- furrr::future_pmap(.l = l.args,
                               .f = myGetSymbols,
                               .progress = TRUE)

  }

  df.tickers <- dplyr::bind_rows(purrr::map(my.l, 1))
  df.control <- dplyr::bind_rows(purrr::map(my.l, 2))

  # remove tickers with bad data
  tickers.to.keep <- df.control$ticker[df.control$threshold.decision=='KEEP']
  idx <- df.tickers$ticker %in% tickers.to.keep
  df.tickers <- df.tickers[idx, ]

  # do data manipulations
  if (do_complete_data) {
    ticker <- ref.date <- NULL # for cran check: "no visible binding for global..."
    df.tickers <- tidyr::complete(df.tickers, ticker, ref.date)

    l.out <- lapply(split(df.tickers, f = df.tickers$ticker),
                    df.fill.na)

    df.tickers <- dplyr::bind_rows(l.out)

  }

  # change frequency of data
  if (freq_data != 'daily') {

    str.freq <- switch(freq_data,
                       'weekly' = '1 week',
                       'monthly' = '1 month',
                       'yearly' = '1 year')

    # find the first monday (see issue #19)
    # https://github.com/msperlin/BatchGetSymbols/issues/19
    temp_dates <- seq(as.Date(paste0(lubridate::year(min(df.tickers$ref.date)), '-01-01')),
                      as.Date(paste0(lubridate::year(max(df.tickers$ref.date))+1, '-12-31')),
                      by = '1 day')

    temp_weekdays <- lubridate::wday(temp_dates, week_start = 1)
    first_idx <- min(which(temp_weekdays == 1))
    first_monday <- temp_dates[first_idx]

    if (freq_data == 'weekly') {
      # make sure it starts on a monday
      week.vec <- seq(first_monday,
                      as.Date(paste0(lubridate::year(max(df.tickers$ref.date))+1, '-12-31')),
                      by = str.freq)
    } else {
      # every other case
      week.vec <- seq(as.Date(paste0(lubridate::year(min(df.tickers$ref.date)), '-01-01')),
                      as.Date(paste0(lubridate::year(max(df.tickers$ref.date))+1, '-12-31')),
                      by = str.freq)
    }


    df.tickers$time.groups <- cut(x = df.tickers$ref.date, breaks = week.vec, right = FALSE)

    # set NULL vars for CRAN check: "no visible binding..."
    time.groups <- volume <- price.open <- price.close <- price.adjusted <- NULL
    price.high <- price.low <- NULL

    if (how_to_aggregate == 'first') {

      df.tickers <- df.tickers %>%
        group_by(time.groups, ticker) %>%
        summarise(ref.date = min(ref.date),
                  volume = sum(volume, na.rm = TRUE),
                  price.open = first(price.open),
                  price.high = max(price.high),
                  price.low = min(price.low),
                  price.close = first(price.close),
                  price.adjusted = first(price.adjusted)) %>%
        ungroup() %>%
        #select(-time.groups) %>%
        arrange(ticker, ref.date)


    } else if (how_to_aggregate == 'last') {

      df.tickers <- df.tickers %>%
        group_by(time.groups, ticker) %>%
        summarise(ref.date = min(ref.date),
                  volume = sum(volume, na.rm = TRUE),
                  price.open = first(price.open),
                  price.high = max(price.high),
                  price.low = min(price.low),
                  price.close = last(price.close),
                  price.adjusted = last(price.adjusted) ) %>%
        ungroup() %>%
        #select(-time.groups) %>%
        arrange(ticker, ref.date)
    }


    df.tickers$time.groups <- NULL
  }


  # calculate returns
  df.tickers$ret.adjusted.prices <- calc.ret(df.tickers$price.adjusted,
                                             df.tickers$ticker,
                                             type_return)
  df.tickers$ret.closing.prices  <- calc.ret(df.tickers$price.close,
                                             df.tickers$ticker,
                                             type_return)

  # fix for issue with repeated rows (see git issue 16)
  # https://github.com/msperlin/BatchGetSymbols/issues/16
  df.tickers = unique(df.tickers)

  # remove rownames from output (see git issue #18)
  # https://github.com/msperlin/BatchGetSymbols/issues/18
  rownames(df.tickers) <- NULL

  my.l <- list(df.control = df.control,
               df.tickers = df.tickers)

  # check if cach folder is tempdir()
  flag <- stringr::str_detect(cache_folder,
                              pattern = stringr::fixed(tempdir()))

  if (!flag) {
    warning(stringr::str_glue('\nIt seems you are using a non-default cache folder at {cache_folder}. ',
                              'Be aware that if any stock event -- split or dividend -- happens ',
                              'in between cache files, the resulting aggregate cache data will not correspond to reality as ',
                              'some part of the price data will not be adjusted to the event. ',
                              'For safety and reproducibility, my suggestion is to use cache system only ',
                              'for the current session with tempdir(), which is the default option.') )
  }

  # enable dplyr group message
  options(dplyr.summarise.inform = TRUE)

  return(my.l)
}
