# Get clean data from yahoo/google
yf_get_clean_data <- function(ticker,
                              first_date,
                              last_date) {


  # dont push luck with yahoo servers
  # No problem in my testings, so far. You can safely leave it unrestricted
  # Sys.sleep(0.5)

  # set empty df for errors
  df_raw <- dplyr::tibble()

  # 2021-06-18 use quantmod::getSymbol
  suppressMessages({
    suppressWarnings({
      try({
        df_raw <- quantmod::getSymbols(Symbols = ticker,
                                         src = 'yahoo',
                                         from = first_date,
                                         to = last_date,
                                         auto.assign = F)
        },
          silent = T)

    }) })

  # change dates to unix (yf links use unix dates)
  #first_date_unix <- date_to_unix(first_date)
  #last_date_unix <- date_to_unix(last_date)

  # old link results in 401 after some tries
  # yf_csv_link <- stringr::str_glue(
  #   'https://query1.finance.yahoo.com/v7/finance/download/{ticker}',
  #   '?period1={first_date_unix}&period2={last_date_unix}&interval=1d&events=history&includeAdjustedClose=true'
  # )

  # new link:
  # https://stackoverflow.com/questions/44030983/yahoo-finance-url-not-working/44168805
  # yf_json_link <- stringr::str_glue(
  #   "https://query2.finance.yahoo.com/v8/finance/chart/{ticker}?symbol={ticker}&",
  #   "period1={first_date_unix}&period2={last_date_unix}&interval=1d"
  # )

  # yf_json_link <- stringr::str_glue(
  #   "https://query2.finance.yahoo.com/v8/finance/chart/PETR3.SA?symbol=PETR3.SA&period1=0&period2=9999999999&interval=1d"
  # )

  # l <- jsonlite::fromJSON(yf_json_link)
  #
  # ref_date <- unix_to_date(l$chart$result$timestamp[[1]])
  # price_adjusted <- l$chart$result$indicators$adjclose[[1]][[1]][[1]]
  # price_high <- l$chart$result$indicators$quote[[1]][[1]][[1]]
  # price_low <- l$chart$result$indicators$quote[[1]][[3]][[1]]
  # price_open <- l$chart$result$indicators$quote[[1]][[4]][[1]]
  # price_close <- l$chart$result$indicators$quote[[1]][[5]][[1]]
  # volume <- l$chart$result$indicators$quote[[1]][[2]][[1]]
  #
  # df_raw <- dplyr::tibble(
  #   ref_date = ref_date,
  #   ticker = ticker,
  #   price_high,
  #   price_low,
  #   price_open,
  #   price_close,
  #   price_adjusted,
  #   volume
  # ) |>
  #   dplyr::arrange(ref_date)  # make sure dates are sorted,

  # PREVIOUS code using json

  # my_cols <- readr::cols(
  #   Date = readr::col_date(format = ""),
  #   Open = readr::col_double(),
  #   High = readr::col_double(),
  #   Low = readr::col_double(),
  #   Close = readr::col_double(),
  #   `Adj Close` = readr::col_double(),
  #   Volume = readr::col_double()
  # )
  #
  # suppressWarnings({
  #   try(
  #     {
  #       df_raw <- readr::read_csv(yf_csv_link, col_types = my_cols) |>
  #       dplyr::mutate(ticker = ticker) |>
  #       dplyr::rename(
  #         ref_date = Date,
  #         price_open = Open,
  #         price_high = High,
  #         price_low = Low,
  #         price_close = Close,
  #         price_adjusted = `Adj Close`,
  #         volume = Volume
  #       ) |>
  #       dplyr::arrange(ref_date) |> # make sure dates are sorted,
  #       dplyr::relocate(ticker, ref_date)
  #     },
  #     silent = T
  #   )
  # })

  # in case of error, return empty df
  if (nrow(df_raw) == 0) {
    return(df_raw)
  }

  # fix df_raw
  ref_date <- zoo::index(df_raw)
  df_raw <- dplyr::as_tibble(df_raw) |>
    mutate(ref_date = ref_date,
           ticker = ticker) |>
    dplyr::as_tibble(df_raw[!duplicated(zoo::index(df_raw))])

  colnames(df_raw) <- c('price_open','price_high','price_low',
                        'price_close','volume','price_adjusted',
                        'ref_date', 'ticker')

  # futher organize
  df_raw <- df_raw |>
    dplyr::arrange(ref_date) |> # make sure dates are sorted,
    dplyr::relocate(ticker, ref_date) # relocate columns

  # make sure only unique rows are returned
  df_raw <- unique(df_raw)

  # remove rows with NA
  idx <- !is.na(df_raw$price_adjusted)
  df_raw <- df_raw[idx, ]

  return(df_raw)
}
