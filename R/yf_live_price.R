#' Yahoo Finance Live Prices
#'
#' This function will use the json api to retrieve live prices from Yahoo finance.
#'
#' @param ticker a single ticker symbol
#'
#' @return a tibble with live prices
#' @export
#'
#' @examples
#' yfR::yf_live_prices("PETR4.SA")
#'
yf_live_prices <- function(ticker){

  if (length(ticker) > 1) {
    cli::cli_abort("input ticker should have only one symbol (found >1)")
  }

  url <- glue::glue("https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?region=US&lang=pt-BR&includePrePost=false&interval=1m&useYfid=true&range=1d&corsDomain=finance.yahoo.com&.tsrc=finance")

  df_prices <- tibble::tibble()

  try({
    df_prices <- httr::GET(url) |>
      httr::content("text") |>
      jsonlite::fromJSON() |>
      purrr::pluck("chart","result") |>
      dplyr::select(meta) |>
      tidyr::unnest(meta) |>
      dplyr::select(
        ticker = symbol,
        time_stamp  = regularMarketTime,
        price = regularMarketPrice,
        last_price = previousClose) |>
      dplyr::mutate(daily_change = (price - last_price)/last_price) |>
      dplyr::mutate(time_stamp = (as.POSIXct(time_stamp, origin="1970-01-01")))
  })

  if (nrow(df_prices) == 0) {
    cli::cli_abort("Can't find ticker {ticker}..")
  }

  return(df_prices)

}
