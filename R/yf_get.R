#' Download financial data from Yahoo Finance
#'
#' Based on a ticker (id of a stock) and time period, this function will
#' download stock price data from Yahoo Finance and organizes it in the long
#' format. Yahoo Finance <https://finance.yahoo.com/> provides a vast repository of
#' stock price data around the globe. It cover a significant number of markets
#' and assets, being used extensively in academic research and teaching. In
#' the website you can lookup the ticker of a company.
#'
#' @section The cache system:
#'
#' The yfR`s cache system is basically a bunch of rds files that are saved every time
#' data is imported from YF. It indexes all data by ticker and time period. Whenever
#' a user asks for a dataset, it first checks if the ticker/time period exists in
#' cache and, if it does, loads the data from the rds file.
#'
#' By default, a temporary folder is used (see function
#' \link{yf_cachefolder_get}, which means that all cache files are
#' session-persistent. In practice, whenever you restart your R/RStudio session,
#' all cache files are lost. This is a choice I've made due to the fact that
#' merging adjusted stock price data after corporate events (dividends/splits)
#' is a mess and prone to errors. This only happens for stock price data,
#' and not indices data.
#'
#' If you really need a persistent cache folder, which is Ok for indices data,
#'  simply set a path with argument cache_folder (see warning section).
#'
#' @section Warning:
#'
#' Be aware that when using cache system in a local folder (and not the default
#'  tempdir()), the aggregate prices series might not match if
#' a split or dividends event happens in between cache files.
#'
#' @param tickers A single or vector of tickers. If not sure whether the ticker is
#' available, search for it in YF <https://finance.yahoo.com/>.
#' @param first_date The first date of query (Date or character as YYYY-MM-DD)
#' @param last_date The last date of query (Date or character as YYYY-MM-DD)
#' @param bench_ticker The ticker of the benchmark asset used to compare dates.
#' My suggestion is to use the main stock index of the market from where the
#' data is coming from (default = ^GSPC (SP500, US market))
#' @param type_return Type of price return to calculate:
#' 'arit' - arithmetic (default), 'log' - log returns.
#' @param freq_data Frequency of financial data: 'daily' (default),
#' 'weekly', 'monthly', 'yearly'
#' @param how_to_aggregate Defines whether to aggregate the data using the
#' first observations of the aggregating period or last ('first', 'last').
#'  For example, if freq_data = 'yearly' and how_to_aggregate = 'last', the
#'  last available day of the year will be used for all
#'  aggregated values such as price_adjusted. (Default = "last")
#' @param thresh_bad_data A percentage threshold for defining bad data. The
#' dates of the benchmark ticker are compared to each asset. If the percentage
#' of non-missing dates with respect to the benchmark ticker is lower than
#' thresh_bad_data, the function will ignore the asset (default = 0.75)
#' @param do_complete_data Return a complete/balanced dataset? If TRUE, all
#' missing pairs of ticker-date will be replaced by NA or closest price
#' (see input do_fill_missing_prices). Default = FALSE.
#' @param do_cache Use cache system? (default = TRUE)
#' @param cache_folder Where to save cache files?
#' (default = yfR::yf_cachefolder_get() )
#' @param do_parallel Flag for using parallel or not (default = FALSE).
#' Before using parallel, make sure you call function future::plan() first.
#' See <https://furrr.futureverse.org/> for more details.
#' @param be_quiet Flag for not printing statements (default = FALSE)
#'
#' @return A dataframe with the financial data for working days, when markets
#' are open. All price data is \strong{measured} at the unit of the financial
#' exchange. For example, price
#' data for META (NYSE/US) is measures in dollars, while price data for
#' PETR3.SA (B3/BR) is measured in Reais (Brazilian currency).
#'
#' The return dataframe contains the following columns:
#'
#' \describe{
#'   \item{ticker}{The requested tickers (ids of stocks)}
#'   \item{ref_date}{The reference day (this can also be year/month/week when
#'   using argument freq_data)}
#'   \item{price_open}{The opening price of the day/period}
#'   \item{price_high}{The highest price of the day/period}
#'   \item{price_close}{The close/last price of the day/period}
#'   \item{volume}{The financial volume of the day/period}
#'   \item{price_adjusted}{The stock price adjusted for corporate events such
#'   as splits, dividends and others -- this is usually what you want/need for
#'   studying stocks as it represents the actual financial performance of
#'   stockholders}
#'   \item{ret_adjusted_prices}{The arithmetic or log return (see input type_return) for
#'   the adjusted stock prices}
#'   \item{ret_adjusted_prices}{The arithmetic or log return (see input type_return) for
#'   the closing stock prices}
#'   \item{cumret_adjusted_prices}{The accumulated arithmetic/log return for the period (starts at 100\%)}
#'   }
#'
#' @export
#'
#' @examples
#'
#' \donttest{
#' tickers <- c("TSLA", "MMM")
#'
#' first_date <- Sys.Date() - 30
#' last_date <- Sys.Date()
#'
#' df_yf <- yf_get(
#'   tickers = tickers,
#'   first_date = first_date,
#'   last_date = last_date
#' )
#'
#' print(df_yf)
#' }
yf_get <- function(tickers,
                   first_date = Sys.Date() - 30,
                   last_date = Sys.Date(),
                   thresh_bad_data = 0.75,
                   bench_ticker = "^GSPC",
                   type_return = "arit",
                   freq_data = "daily",
                   how_to_aggregate = "last",
                   do_complete_data = FALSE,
                   do_cache = TRUE,
                   cache_folder = yf_cachefolder_get(),
                   do_parallel = FALSE,
                   be_quiet = FALSE) {

  # check for internet
  if (!curl::has_internet()) {
    stop("Can't find an active internet connection...")
  }

  # check cache folder
  if ((do_cache) & (!dir.exists(cache_folder))) dir.create(cache_folder,
                                                           recursive = TRUE)

  # check options
  possible_values <- c("arit", "log")
  if (!any(type_return %in% possible_values)) {
    stop(paste0("Input type.ret should be one of:\n\n",
                paste0(possible_values,
                       collapse = "\n")
    )
    )
  }

  possible_values <- c("first", "last")
  if (!any(how_to_aggregate %in% possible_values)) {
    stop(paste0("Input how_to_aggregate should be one of:\n\n",
                paste0(possible_values, collapse = "\n")))
  }

  # check for NA
  if (any(is.na(tickers))) {
    my_msg <- paste0(
      "Found NA value in ticker vector.",
      "You need to remove it before running yfR::yf_get()."
    )
    stop(my_msg)
  }

  possible_values <- c("daily", "weekly", "monthly", "yearly")
  if (!any(freq_data %in% possible_values)) {
    stop(paste0("Input freq_data should be one of:\n\n",
                paste0(possible_values, collapse = "\n")))
  }

  # check date class
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  if (!methods::is(first_date, "Date")) {
    stop("can't change class of first_date to 'Date'")
  }

  if (!methods::is(last_date, "Date")) {
    stop("can't change class of last_date to 'Date'")
  }

  if (last_date <= first_date) {
    stop(paste0("The last_date is lower (less recent) or equal to first_date.",
                " Please check your dates!"))
  }

  # check tickers
  if (!is.null(tickers)) {
    tickers <- as.character(tickers)

    if (!methods::is(tickers, "character")) {
      stop("The input tickers should be a character object.")
    }
  }

  # sort tickers (makes sure acum ret is correct)
  tickers <- sort(tickers)

  # check threshold
  if ((thresh_bad_data < 0) | (thresh_bad_data > 1)) {
    stop("Input thresh_bad_data should be a proportion between 0 and 1")
  }

  # disable dplyr group message and respect user choice
  # will be null if options is not set
  default_dplyr_summ <- options("dplyr.summarise.inform")[[1]]

  # disable and enable at end with on exit
  options(dplyr.summarise.inform = FALSE)

  on.exit({
    if (is.logical(default_dplyr_summ)) {
      options(dplyr.summarise.inform = default_dplyr_summ)
    }
  })

  # check if using do_parallel = TRUE
  # 20220501 Yahoo finance started setting limits to api calls, which
  # invalidates the use of any parallel computation
  if (do_parallel) {
    my_message <- stringr::str_glue(
      "Since 2022-04-25, Yahoo Finance started to set limits to api calls, ",
      "resulting in 401 errors. When using parallel computations for fetching ",
      "data, the limit is reached easily. Said that, the parallel option is now",
      " disabled by default. Please set do_parallel = FALSE to use this function.",
      "\n\n",
      "Returning empty dataframe.")

    cli::cli_alert_danger(my_message)
    return(data.frame())

  }

  # first screen msgs

  if (!be_quiet) {
    days_diff <- as.numeric(last_date - first_date)

    # cli::cli_h1('yfR -- Yahoo Finance for R')

    my_msg <- paste0(
      "\nRunning yfR for {length(tickers)} stocks | ",
      "{as.character(first_date)} --> ",
      "{as.character(last_date)} ({days_diff} days)"
    )
    cli::cli_h2(my_msg)

    my_msg <- set_cli_msg(
      "Downloading data for benchmark ticker {bench_ticker}",
      level = 0
    )

    cli::cli_alert_info(my_msg)
  }

  # get benchmark ticker data
  df_bench <- yf_data_single(
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
      .f = yf_data_single
    )
  } else {

    # available cores in R session
    available_cores <- future::availableCores()
    used_cores <- future::nbrOfWorkers()

    if (!be_quiet) {

      cli::cli_h3(
        'Running yfR with parallel backend (using {used_cores} of {available_cores} available cores)')

    }

    # test if plan() was called
    msg <- utils::capture.output(future::plan())

    # "sequential is the default plan
    flag <- stringr::str_detect(msg[1], "sequential")

    if (flag) {
      stop(paste0(
        "When using do_parallel = TRUE, you need to call future::plan() to ',
        configure your parallel settings. \n",
        "A suggestion, write the following lines:\n\n",
        "future::plan(future::multisession, ",
        "workers = floor(parallel::detectCores()/2))",
        "\n\n",
        "The last line should be placed just before calling get_yf_data. ",
        "Notice it will use half of your available cores so that your OS has ",
        "some room to breathe."
      ))
    }

    my_l <- furrr::future_pmap(
      .l = l_args,
      .f = yf_data_single,
      .progress = TRUE,
      # fixes warnings about seed
      .options = furrr::furrr_options(seed = TRUE)
    )

  }

  # remove any element that is not a list
  l_classes <- purrr::map_chr(my_l, class)
  idx <- l_classes != "list"
  my_l[idx] <- NULL

  cli::cli_alert_info('Binding price data')
  df_tickers <- dplyr::bind_rows(purrr::map(my_l, 1))
  df_control <- dplyr::bind_rows(purrr::map(my_l, 2))

  # make sure data is in the output
  if (nrow(df_tickers) == 0) {
    stop(
      paste0(
        "Resulting data has 0 rows.. Are your tickers correct?",
        " Search your ticker at <https://finance.yahoo.com/>."
      )
    )
  }

  # remove tickers with bad data
  tickers_to_keep <- df_control$ticker[df_control$threshold_decision == "KEEP"]
  idx <- df_tickers$ticker %in% tickers_to_keep
  df_tickers <- df_tickers[idx, ]

  # do data manipulations
  if (do_complete_data) {

    cli::cli_alert_info("\nCompleting data points (do_complete_data = TRUE)")

    # makes sure each data point is ticker/ref_date is available in output
    # missing are set as NA
    df_tickers <- df_tickers %>%
      dplyr::group_by(ticker, ref_date) %>%
      tidyr::complete()

  }

  # change frequency of data
  if (freq_data != "daily") {

    str_freq <- switch(freq_data,
                       "weekly" = "1 week",
                       "monthly" = "1 month",
                       "yearly" = "1 year"
    )

    # find the first monday (see issue #19 in BatchGetsymbols)
    # https://github.com/msperlin/BatchGetSymbols/issues/19
    min_year <- as.Date(paste0(
      lubridate::year(min(df_tickers$ref_date)),
      "-01-01"
    )
    )
    max_year <- as.Date(paste0(
      lubridate::year(max(df_tickers$ref_date)) + 1,
      "-12-31"
    )
    )

    temp_dates <- seq(min_year, max_year,
                      by = "1 day"
    )

    temp_weekdays <- lubridate::wday(temp_dates, week_start = 1)
    first_idx <- min(which(temp_weekdays == 1))
    first_monday <- temp_dates[first_idx]

    if (freq_data == "weekly") {

      # make sure it starts on a monday
      week_vec <- seq(first_monday,
                      as.Date(paste0(
                        lubridate::year(max(df_tickers$ref_date)) + 1, "-12-31")
                      ),
                      by = str_freq
      )

    } else {

      # every other case
      week_vec <- seq(as.Date(paste0(
        lubridate::year(min(df_tickers$ref_date)), "-01-01")
      ),
      as.Date(paste0(
        lubridate::year(max(df_tickers$ref_date)) + 1, "-12-31")
      ),
      by = str_freq
      )

    }

    df_tickers$time_groups <- cut(
      x = df_tickers$ref_date,
      breaks = week_vec,
      right = FALSE
    )

    if (how_to_aggregate == "first") {

      df_tickers <- df_tickers %>%
        dplyr::group_by(time_groups, ticker) %>%
        dplyr::summarise(
          ref_date = min(ref_date),
          price_open = dplyr::first(price_open),
          price_high = max(price_high),
          price_low = min(price_low),
          price_close = dplyr::first(price_close),
          price_adjusted = dplyr::first(price_adjusted),
          volume = sum(volume, na.rm = TRUE)
        ) %>%
        dplyr::ungroup() %>%
        dplyr::arrange(ticker, ref_date)

    } else if (how_to_aggregate == "last") {

      df_tickers <- df_tickers %>%
        dplyr::group_by(time_groups, ticker) %>%
        dplyr::summarise(
          ref_date = min(ref_date),
          volume = sum(volume, na.rm = TRUE),
          price_open = dplyr::last(price_open),
          price_high = max(price_high),
          price_low = min(price_low),
          price_close = dplyr::last(price_close),
          price_adjusted = dplyr::last(price_adjusted)
        ) %>%
        dplyr::ungroup() %>%
        dplyr::arrange(ticker, ref_date)

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

  # calculate acumulated returns
  df_tickers$cumret_adjusted_prices <- calc_cum_ret(
    df_tickers$ret_adjusted_prices,
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

  # check if cache folder is tempdir()
  flag <- stringr::str_detect(cache_folder,
                              pattern = stringr::fixed(tempdir())
  )

  if (!flag) {
    warning(stringr::str_glue(
      "\nIt seems you are using a non-default cache folder at {cache_folder}. ",
      "Be aware that, for individual stocks, yfR **does not** garantee price integrity ",
      "in between days. Some stock events adjust prices recursively, meaning that one ",
      "can have a different adjusted price for queries executed in different days. ",
      "For safety and reproducibility, my suggestion ",
      "is to use the default cache_folder at tempdir(). ",
      "\n\n",
      "This issue only affects individual stocks. For market indices, such as SP500,",
      " I dont expect any problem in having a persistent cache folder, outside .",
      "of tempdir()."
    ))
  }

  # setup final output (ungrouped tibble)
  df_out <- df_tickers %>%
    dplyr::ungroup()

  attributes(df_out)$df_control <- df_control

  # last messages
  cli::cli_h1("Diagnostics")

  n_requested <- length(tickers)
  n_got <- dplyr::n_distinct(df_out$ticker)

  this_morale <- get_morale_boost()

  cli::cli_alert_success(
    paste0(
      "Returned dataframe with {nrow(df_out)} rows",
      " -- {this_morale}"
    )
  )

  # check cache size
  if (do_cache) {
    cache_files <- list.files(cache_folder, full.names = TRUE)
    size_files <- sum(sapply(cache_files, file.size))

    size_str <- humanize::natural_size(size_files)
    n_files <- length(list.files(cache_folder))

    cli::cli_alert_info("Using {size_str} at {cache_folder} for {n_files} cache files")
  }

  success_rate <- n_got/n_requested

  cli::cli_alert_info(
    paste0("Out of {n_requested} requested tickers, you got {n_got}",
           " ({scales::percent(success_rate)})")
  )

  if (success_rate < 0.75) {

    extra_msg <- paste0(
      "You either inputed wrong tickers, or ranned into YF call limit? My advice:",
      " check your input tickers, wait 15 minutes and try again."
    )
    cli::cli_alert_danger(
      paste0(
        'You got data on less than {scales::percent(0.75)} of requested tickers. ',
        "{extra_msg}"
      )
    )

    idx <- !tickers %in% unique(df_tickers$ticker)
    missing_tickers <- tickers[idx]
    cli::cli_alert_info(
      paste0("Missing tickers: ",
             paste0(missing_tickers, collapse = ", "))
    )

  }

  return(df_out)
}
