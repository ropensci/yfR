# Get clean data from yahoo/google using quantmod::getSymbols
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
  if (nrow(df_raw) == 0) return(df_raw)

  # fix df_raw
  ref_date <- zoo::index(df_raw)
  df_raw <- dplyr::as_tibble(df_raw) |>
    dplyr::mutate(ref_date = ref_date,
           ticker = ticker) |>
    dplyr::as_tibble(df_raw[!duplicated(zoo::index(df_raw))])

  colnames(df_raw) <- c('price_open','price_high','price_low',
                        'price_close','volume','price_adjusted',
                        'ref_date', 'ticker')

  # further organization
  df_raw <- df_raw |>
    dplyr::arrange(ref_date) |> # make sure dates are sorted,
    dplyr::relocate(ticker, ref_date) # relocate columns

  # make sure each date point only appear once
  # sometimes, yf outputs two data points for the same date (not sure why)
  df_raw <- df_raw |>
    dplyr::group_by(ref_date, ticker) |>
    dplyr::filter(dplyr::row_number()==1)

  # make sure only unique rows are returned
  df_raw <- unique(df_raw)

  # remove rows with NA
  idx <- !is.na(df_raw$price_adjusted)
  df_raw <- df_raw[idx, ]

  return(df_raw)
}
