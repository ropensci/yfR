#' Function to download financial data
#'
#' This function downloads financial data from Yahoo Finance. Based on a set of tickers and a time period, the function will download the data for each ticker and return a report of the process, along with the actual data in the long dataframe format.
#' The main advantage of the function is that it automatically recognizes the source of the dataset from the ticker and structures the resulting data from different sources in the long format.
#' A caching system is also available, making it very fast.
#'
#' @section Warning:
#'
#' Be aware that when using cache system in a local folder (and not the default tempdir()), the aggregate prices series might not match if
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
#'  aggregated values such as price_adjusted.
#' @param thresh_bad_data A percentage threshold for defining bad data. The dates of the benchmark ticker are compared to each asset. If the percentage of non-missing dates
#'  with respect to the benchmark ticker is lower than thresh_bad_data, the function will ignore the asset (default = 0.75)
#' @param do_complete_data Return a complete/balanced dataset? If TRUE, all missing pairs of ticker-date will be replaced by NA or closest price (see input do_fill_missing_prices). Default = FALSE.
#' @param do_fill_missing_prices Finds all missing prices and replaces them by their closest price with preference for the previous price. This ensures a balanced dataset for all assets, without any NA. Default = TRUE.
#' @param do_cache Use cache system? (default = TRUE)
#' @param cache_folder Where to save cache files? (default = file.path(tempdir(), 'BGS_Cache') )
#' @param do_parallel Flag for using parallel or not (default = FALSE). Before using parallel, make sure you call function future::plan() first.
#' @param be_quiet Logical for printing statements (default = FALSE)
#' @return A dataframe with stock prices.
#' @export
#' @import dplyr
#'
#' @examples
#' tickers <- c("FB", "MMM")
#'
#' first_date <- Sys.Date() - 15
#' last_date <- Sys.Date()
#'
#' df_yf <- yf_get_data(
#'   tickers = tickers,
#'   first_date = first_date,
#'   last_date = last_date,
#'   do_cache = FALSE
#' )
#'
#' print(df_yf)
yf_get_data <- function(tickers,
                        first_date = Sys.Date() - 30,
                        last_date = Sys.Date(),
                        thresh_bad_data = 0.75,
                        bench_ticker = "^GSPC",
                        type_return = "arit",
                        freq_data = "daily",
                        how_to_aggregate = "last",
                        do_complete_data = FALSE,
                        do_fill_missing_prices = TRUE,
                        do_cache = TRUE,
                        cache_folder = yf_get_default_cache_folder(),
                        do_parallel = FALSE,
                        be_quiet = FALSE) {

  # check for internet
  if (!curl::has_internet()) {
    stop("Cant find an active internet connection...")
  }

  # check cache folder
  if ((do_cache) & (!dir.exists(cache_folder))) dir.create(cache_folder, recursive = TRUE)

  # check options
  possible_values <- c("arit", "log")
  if (!any(type_return %in% possible_values)) {
    stop(paste0("Input type.ret should be one of:\n\n", paste0(possible_values, collapse = "\n")))
  }

  possible_values <- c("first", "last")
  if (!any(how_to_aggregate %in% possible_values)) {
    stop(paste0("Input how_to_aggregate should be one of:\n\n", paste0(possible_values, collapse = "\n")))
  }

  # check for NA
  if (any(is.na(tickers))) {
    my_msg <- paste0(
      "Found NA value in ticker vector.",
      "You need to remove it before running BatchGetSymbols."
    )
    stop(my_msg)
  }

  possible_values <- c("daily", "weekly", "monthly", "yearly")
  if (!any(freq_data %in% possible_values)) {
    stop(paste0("Input freq_data should be one of:\n\n", paste0(possible_values, collapse = "\n")))
  }

  # check date class
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  if (class(first_date) != "Date") {
    stop("ERROR: Input first_date should be of class Date")
  }

  if (class(last_date) != "Date") {
    stop("ERROR: Input first_date should be of class Date")
  }

  if (last_date <= first_date) {
    stop("The last_date is lower (less recent) or equal to first_date. Check your dates!")
  }

  # check tickers
  if (!is.null(tickers)) {
    tickers <- as.character(tickers)

    if (class(tickers) != "character") {
      stop("The input tickers should be a character object.")
    }
  }

  # check threshold
  if ((thresh_bad_data < 0) | (thresh_bad_data > 1)) {
    stop("Input thresh_bad_data should be a proportion between 0 and 1")
  }

  # disable dplyr group message
  options(dplyr.summarise.inform = FALSE)

  # first screen msgs

  if (!be_quiet) {
    days_diff <- as.numeric(last_date - first_date)

    # cli::cli_h1('yfR -- Yahoo Finance for R')

    my_msg <- paste0(
      "\nRunning yfR for {length(tickers)} stocks | ",
      "{as.character(first_date)} --> {as.character(last_date)} ({days_diff} days)"
    )
    cli::cli_h2(my_msg)

    my_msg <- set_cli_msg("Downloading data for benchmark ticker {bench_ticker}",
      level = 0
    )

    cli::cli_alert_info(my_msg)
  }

  df_bench <- yf_get_single_ticker(
    ticker = bench_ticker,
    i_ticker = 1,
    length_tickers = 1,
    first_date = first_date,
    last_date = last_date,
    do_cache = do_cache,
    cache_folder = cache_folder,
    be_quiet = TRUE
  )

  # run fetching function for all tickers

  l_args <- list(
    ticker = tickers,
    i_ticker = seq_along(tickers),
    length_tickers = length(tickers),
    first_date = first_date,
    last_date = last_date,
    do_cache = do_cache,
    cache_folder = cache_folder,
    df_bench = rep(list(df_bench), length(tickers)),
    thresh_bad_data = thresh_bad_data,
    be_quiet = be_quiet
  )

  if (!do_parallel) {
    my_l <- purrr::pmap(
      .l = l_args,
      .f = yf_get_single_ticker
    )
  } else {

    # find number of used cores
    formals_parallel <- formals(future::plan())
    used_workers <- formals_parallel$workers

    available_cores <- future::availableCores()

    if (!be_quiet) {
      message(paste0(
        "\nRunning parallel BatchGetSymbols with ",
        used_workers, " cores (",
        available_cores, " available)"
      ), appendLF = FALSE)
      message("\n\n", appendLF = FALSE)
    }


    # test if plan() was called
    msg <- utils::capture.output(future::plan())

    flag <- stringr::str_detect(msg[1], "sequential")

    if (flag) {
      stop(paste0(
        "When using do_parallel = TRUE, you need to call future::plan() to configure your parallel settings. \n",
        "A suggestion, write the following lines:\n\n",
        "future::plan(future::multisession, workers = floor(parallel::detectCores()/2))",
        "\n\n",
        "The last line should be placed just before calling BatchGetSymbols. ",
        "Notice it will use half of your available cores so that your OS has some room to breathe."
      ))
    }


    my_l <- furrr::future_pmap(
      .l = l_args,
      .f = yf_get_single_ticker,
      .progress = TRUE
    )
  }

  df_tickers <- dplyr::bind_rows(purrr::map(my_l, 1))
  df_control <- dplyr::bind_rows(purrr::map(my_l, 2))

  # remove tickers with bad data
  tickers_to_keep <- df_control$ticker[df_control$threshold_decision == "KEEP"]
  idx <- df_tickers$ticker %in% tickers_to_keep
  df_tickers <- df_tickers[idx, ]

  # do data manipulations
  if (do_complete_data) {
    df_tickers <- tidyr::complete(df_tickers, ticker, ref_date)

    l_out <- lapply(
      split(df_tickers,
        f = df_tickers$ticker
      ),
      df_fill_na
    )

    df_tickers <- dplyr::bind_rows(l_out)
  }

  # change frequency of data
  if (freq_data != "daily") {
    str_freq <- switch(freq_data,
      "weekly" = "1 week",
      "monthly" = "1 month",
      "yearly" = "1 year"
    )

    # find the first monday (see issue #19)
    # https://github.com/msperlin/BatchGetSymbols/issues/19
    temp_dates <- seq(as.Date(paste0(lubridate::year(min(df_tickers$ref_date)), "-01-01")),
      as.Date(paste0(lubridate::year(max(df_tickers$ref_date)) + 1, "-12-31")),
      by = "1 day"
    )

    temp_weekdays <- lubridate::wday(temp_dates, week_start = 1)
    first_idx <- min(which(temp_weekdays == 1))
    first_monday <- temp_dates[first_idx]

    if (freq_data == "weekly") {
      # make sure it starts on a monday
      week_vec <- seq(first_monday,
        as.Date(paste0(lubridate::year(max(df_tickers$ref_date)) + 1, "-12-31")),
        by = str_freq
      )
    } else {
      # every other case
      week_vec <- seq(as.Date(paste0(lubridate::year(min(df_tickers$ref_date)), "-01-01")),
        as.Date(paste0(lubridate::year(max(df_tickers$ref_date)) + 1, "-12-31")),
        by = str_freq
      )
    }


    df_tickers$time_groups <- cut(
      x = df_tickers$ref_date,
      breaks = week_vec,
      right = FALSE
    )

    if (how_to_aggregate == "first") {
      df_tickers <- df_tickers |>
      group_by(time_groups, ticker) |>
      summarise(
        ref_date = min(ref_date),
        price_open = first(price_open),
        price_high = max(price_high),
        price_low = min(price_low),
        price_close = first(price_close),
        price_adjusted = first(price_adjusted),
        volume = sum(volume, na.rm = TRUE)
      ) |>
      ungroup() |>
      # select(-time_groups) |>
      arrange(ticker, ref_date)
    } else if (how_to_aggregate == "last") {
      df_tickers <- df_tickers |>
      group_by(time_groups, ticker) |>
      summarise(
        ref_date = min(ref_date),
        volume = sum(volume, na.rm = TRUE),
        price_open = first(price_open),
        price_high = max(price_high),
        price_low = min(price_low),
        price_close = last(price_close),
        price_adjusted = last(price_adjusted)
      ) |>
      ungroup() |>
      # select(-time_groups) |>
      arrange(ticker, ref_date)
    }


    df_tickers$time_groups <- NULL
  }


  # calculate returns
  df_tickers$ret_adjusted_prices <- calc_ret(
    df_tickers$price_adjusted,
    df_tickers$ticker,
    type_return
  )
  df_tickers$ret_closing_prices <- calc_ret(
    df_tickers$price_close,
    df_tickers$ticker,
    type_return
  )

  # fix for issue with repeated rows (see git issue 16)
  # https://github.com/msperlin/BatchGetSymbols/issues/16
  df_tickers <- unique(df_tickers)

  # remove rownames from output (see git issue #18)
  # https://github.com/msperlin/BatchGetSymbols/issues/18
  rownames(df_tickers) <- NULL

  my_l <- list(
    df_control = df_control,
    df_tickers = df_tickers
  )

  # check if cach folder is tempdir()
  flag <- stringr::str_detect(cache_folder,
    pattern = stringr::fixed(tempdir())
  )

  if (!flag) {
    warning(stringr::str_glue(
      "\nIt seems you are using a non-default cache folder at {cache_folder}. ",
      "Be aware that if any stock event -- split or dividend -- happens ",
      "in between cache files, the resulting aggregate cache data will not correspond to reality as ",
      "some part of the price data will not be adjusted to the event. ",
      "For safety and reproducibility, my suggestion is to use cache system only ",
      "for the current session with tempdir(), which is the default option."
    ))
  }

  # setup final output
  df_out <- df_tickers
  attributes(df_out)$df_control <- df_control

  # enable dplyr group message
  options(dplyr.summarise.inform = TRUE)

  return(df_out)
}
