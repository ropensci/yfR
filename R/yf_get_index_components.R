#' Get current composition of stock indices
#'
#' @param mkt_index the index (e.g. IBOV, SP500, FTSE)
#' @inheritParams yf_get_data
#'
#' @return A dataframe with the index compositino (column might vary)
#' @export
#'
#' @examples
#' df_sp500 <- yf_get_index_comp("SP500")
yf_get_index_comp <- function(mkt_index,
                              do_cache = TRUE,
                              cache_folder = yf_get_default_cache_folder()) {

  available_indices <- yf_get_available_indices()
  if (!any(mkt_index %in% available_indices)) {
    stop(stringr::str_glue(
      "Index {mkt_index} is no available within the options: ",
      ' {paste0(available_indices, collapse = ", ")}'
    ))
  }

  if (mkt_index == "IBOV") {

    df_index <- yf_get_ibov_stocks(
      do_cache = do_cache,
      cache_folder = cache_folder,
      max_tries = 10
    )

  } else if (mkt_index == "SP500") {

    df_index <- yf_get_sp500_stocks()

  } else if (mkt_index == "FTSE") {

    df_index <- yf_get_ftse_stocks()

  }

  return(df_index)
}


#' Get available indices in package
#'
#' This funtion will return all available market indices that are registered
#' in the package.
#'
#' @return A vector of mkt indices
#' @export
#'
#' @examples
#'
#' av_indices <- yf_get_available_indices()
yf_get_available_indices <- function() {
  available_indices <- c("SP500", "IBOV", "FTSE")

  return(available_indices)
}


#' Function to download the current components of the
#' Ibovespa index from B3 website
yf_get_ibov_stocks <- function(do_cache = TRUE,
                               cache_folder = yf_get_default_cache_folder(),
                               max_tries = 10) {
  cache_file <- file.path(
    cache_folder,
    paste0("Ibov_Composition_", Sys.Date(), ".rds")
  )
  # get list of ibovespa's tickers from wbsite

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df_ibov_comp <- readr::read_rds(cache_file)
      return(df_ibov_comp)
    }
  }

  for (i_try in seq(max_tries)) {
    my_url <- 'https://en.wikipedia.org/wiki/List_of_companies_listed_on_B3'

    df_ibov_comp <- rvest::read_html(my_url) |>
      rvest::html_table()

    df_ibov_comp <- df_ibov_comp[[1]]

    Sys.sleep(0.5)

    if (nrow(df_ibov_comp) > 0) break()
  }

  df_ibov_comp <- df_ibov_comp |>
    dplyr::rename(ticker = Ticker,
                  company = Company,
                  industry = Industry) |>
    dplyr::mutate(type_stock = NA,
                  quantity = NA,
                  percentage_participation = NA,
                  ref_date = Sys.Date(),
                  index = "IBOV",
                  index_ticker = "^BVSP") |>
    dplyr::select(-Headquarters)

  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_ibov_comp, cache_file)
  }

  yf_get_message_index("Ibovespa", nrow(df_ibov_comp))

  return(df_ibov_comp)
}

#' Function to download the current components of the
#' FTSE100 index from Wikipedia
#' @noRd
yf_get_ftse_stocks <- function(do_cache = TRUE,
                               cache_folder = yf_get_default_cache_folder()) {
  cache_file <- file.path(
    cache_folder,
    paste0("yf_ftse100_Composition_", Sys.Date(), ".rds")
  )

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df_ftse <- readr::read_rds(cache_file)
      return(df_ftse)
    }
  }

  my_url <- "https://en.wikipedia.org/wiki/FTSE_100_Index"

  my_xpath <- '//*[@id="mw-content-text"]/div/table[2]' # old xpath
  my_xpath <- '//*[@id="constituents"]'
  df_ftse <- my_url |>
    rvest::read_html() |>
    rvest::html_nodes(xpath = my_xpath) |>
    rvest::html_table()

  df_ftse <- df_ftse[[1]]

  df_ftse <- df_ftse |>
    dplyr::rename(
      ticker = EPIC,
      company = Company,
      sector = names(df_ftse)[3]
    ) |>
    dplyr::mutate(
      index = "FTSE",
      index_ticker = "^FTSE"
    )

  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_ftse, cache_file)
  }

  yf_get_message_index("FTSE", nrow(df_ftse))

  return(df_ftse)
}

#' Function to download the current components of the SP500 index from Wikipedia
#' @noRd
yf_get_sp500_stocks <- function(do_cache = TRUE,
                                cache_folder = yf_get_default_cache_folder()) {
  cache_file <- file.path(
    cache_folder,
    paste0("SP500_Composition_", Sys.Date(), ".rds")
  )

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df_sp500 <- readr::read_rds(cache_file)
      return(df_sp500)
    }
  }

  my_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"

  read_html <- 0 # fix for global variable nagging from BUILD
  my_xpath <- '//*[@id="constituents"]'
  df_sp500 <- my_url |>
    rvest::read_html() |>
    rvest::html_nodes(xpath = my_xpath) |>
    rvest::html_table(fill = TRUE)

  df_sp500 <- df_sp500[[1]]

  df_sp500 <- df_sp500  |>
    dplyr::rename(
      ticker = Symbol,
      company = Security,
      sector = `GICS Sector`
    ) |>
    dplyr::select(ticker, company, sector) |>
    dplyr::mutate(
      index = "SP500",
      index_ticker = "^GSPC"
    )


  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_sp500, cache_file)
  }

  yf_get_message_index("SP500", nrow(df_sp500))
  return(df_sp500)
}

#' Builds index message
#' @noRd
yf_get_message_index <- function(index_in, my_n) {
  cli::cli_alert_success("Got {index_in} composition with {my_n} rows")
  return(invisible(TRUE))
}
