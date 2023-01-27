#' Yahoo Finance Live Prices
#'
#' @param .ticker Ticker de interesse
#'
#' @return Tibble
#' @export
#'
#' @examples
#' yfR::yf_live_prices("PETR4.SA")
#'
yf_live_prices <- function(.ticker){

  url <- glue::glue("https://query1.finance.yahoo.com/v8/finance/chart/{.ticker}?region=US&lang=pt-BR&includePrePost=false&interval=1m&useYfid=true&range=1d&corsDomain=finance.yahoo.com&.tsrc=finance")

  dados <- purrr::possibly(
    .f = ~{
      httr::GET(url) |>
        httr::content("text") |>
        jsonlite::fromJSON() |>
        purrr::pluck("chart","result") |>
        dplyr::select(meta) |>
        tidyr::unnest(meta) |>
        dplyr::select(
          ticker = symbol,
          horario = regularMarketTime,
          cotacao = regularMarketPrice) |>
        dplyr::mutate(horario = (as.POSIXct(horario, origin="1970-01-01")))
    },
    otherwise = NULL
  )

  suppressMessages(
    suppressWarnings(
      dados_vez <- dados()
    )
  )

  if(is.null(dados_vez)){
    usethis::ui_oops("Ticker Inexistente!")
  } else {
    return(dados_vez)
  }
}
