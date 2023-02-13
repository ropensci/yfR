#' Get Yahoo Finance Dividends from a single stock
#'
#' This function will use the json api to retrieve dividends from Yahoo finance.
#'
#' @param ticker a single ticker symbol
#' @param first_date The first date of query (Date or character as YYYY-MM-DD)
#' @param last_date The last date of query (Date or character as YYYY-MM-DD)
#'
#' @return a tibble with dividends
#' @export
#'
#' @examples
#' yf_get_dividends(ticker = "PETR4.SA")
#'
yf_get_dividends <- function(ticker,
                             first_date = Sys.Date() - 365,
                             last_date = Sys.Date()) {

  cli::cli_alert_info(
    paste0("Be aware that YF does not provide a consistent dividend database.",
          " Use this function with caution.")
  )

  if (length(ticker) > 1) {
    cli::cli_abort("input ticker should have only one symbol (found >1)")
  }

  # check for internet
  if (!pingr::is_online()) {
    stop("Can't find an active internet connection...")
  }

  first_date <- base::as.Date(first_date)

  last_date <- base::as.Date(last_date)


  if (!methods::is(first_date, "Date")) {
    stop("can't change class of first_date to 'Date'")
  }

  if (!methods::is(last_date, "Date")) {
    stop("can't change class of last_date to 'Date'")
  }

  first_date_number <- base::as.numeric(
    lubridate::as_datetime(first_date,
                           tz = "America/Sao_Paulo"
  )
  )

  last_date_number <- base::as.numeric(
    lubridate::as_datetime(last_date,
                          tz = "America/Sao_Paulo")
  )

  link <- glue::glue("https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?formatted=true&crumb=DUrcw6zrjLP&lang=en-US&region=US&includeAdjustedClose=true&interval=1d&period1={first_date_number}&period2={last_date_number}&events=capitalGain%7Cdiv%7Csplit&useYfid=true&corsDomain=finance.yahoo.com")

  dividends <- tibble::tibble()

  dividends <- try({
    httr::RETRY(verb = "GET",url = link,) %>%
      httr::content("text") %>%
      jsonlite::fromJSON() %>%
      purrr::pluck("chart", "result", "events", "dividends")
  })

  if(base::is.null(dividends)){
    cli::cli_abort("Can't find ticker {ticker} or don\u00B4t have dividends..")
  } else if (base::nrow(dividends) == 0) {
    cli::cli_abort("Can't find ticker {ticker} or don\u00B4t have dividends..")
  } else {
    dividends <- dividends %>%
      purrr::map_dfr(
        .f = ~{.x}) %>%
      dplyr::as_tibble() %>%
      dplyr::mutate(
        date = base::as.POSIXct(date, origin = "1970-01-01"),
        date = base::as.Date(date),
        ticker = stringr::str_to_upper(string = ticker)
      ) %>%
      dplyr::select(
        ref_date = date,
        ticker,
        dividend = amount
      )
  }

  return(dividends)
}
