#' Get clean data from yahoo/google using quantmod::getSymbols
#' @noRd
yf_data_get_raw <- function(ticker,
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
                                       auto.assign = FALSE)
      },
      silent = TRUE)

    })
  })


  # in case of error, return empty df
  if (nrow(df_raw) == 0) return(df_raw)

  # fix df_raw
  ref_date <- zoo::index(df_raw)
  df_raw <- as.data.frame(df_raw) %>%
    dplyr::mutate(ref_date = ref_date,
                  ticker = ticker)
  #%>%
  # as.data.frame(df_raw[!duplicated(zoo::index(df_raw))])

  colnames(df_raw) <- c('price_open','price_high','price_low',
                        'price_close','volume','price_adjusted',
                        'ref_date', 'ticker')

  # further organization
  df_raw <- df_raw %>%
    dplyr::arrange(ref_date) %>% # make sure dates are sorted,
    dplyr::relocate(ticker, ref_date) # relocate columns

  # make sure each date point only appear once
  # sometimes, yf outputs two data points for the same date (not sure why)
  df_raw <- df_raw %>%
    dplyr::group_by(ref_date, ticker) %>%
    dplyr::filter(dplyr::row_number() == 1)

  # make sure only unique rows are returned
  df_raw <- unique(df_raw)

  # remove rows with NA
  idx <- !is.na(df_raw$price_adjusted)
  df_raw <- df_raw[idx, ]

  return(df_raw)
}
