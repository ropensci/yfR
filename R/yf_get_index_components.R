#' Get current composition of stock indices
#'
#' @param mkt_index the index (e.g. IBOV, SP500, FTSE)
#' @inheritParams yf_get
#' @param force_fallback Logical (TRUE/FALSE). Forces the function to use the
#' fallback system
#'
#' @return A dataframe with the index composition (column might vary)
#' @export
#'
#' @examples
#' df_sp500 <- yf_index_composition("SP500")
yf_index_composition <- function(mkt_index,
                              do_cache = TRUE,
                              cache_folder = yf_cachefolder_get(),
                              force_fallback = FALSE) {

  available_indices <- yf_index_list()
  if (!any(mkt_index %in% available_indices)) {
    stop(stringr::str_glue(
      "Index {mkt_index} is no available within the options: ",
      ' {paste0(available_indices, collapse = ", ")}'
    ))
  }

  if (force_fallback) {
    df_index <- read_fallback(mkt_index)
    return(df_index)
  }

  df_index <- data.frame()
  try({

    if (mkt_index == "IBOV") {

      df_index <- yf_index_ibov(
        do_cache = do_cache,
        cache_folder = cache_folder,
        max_tries = 10
      )

    } else if (mkt_index == "SP500") {

      df_index <- yf_index_sp500()

    } else if (mkt_index == "FTSE") {

      df_index <- yf_index_ftse()

    } else if (mkt_index == "DOW") {

      df_index <- yf_index_dow()

    } else if (mkt_index == "testthat-collection") {

      df_index <- yf_index_test()

    }
  })

  if (nrow(df_index) == 0) {

    cli::cli_alert_info("Failed to import current composition for {mkt_index}. Using fallback index")

    df_index <- read_fallback(mkt_index)

  }

  # fix tickers manually (isse #18)
  df_index <- substitute_tickers(df_index)

  return(df_index)
}

#' Read fallback/static market indices composition from package
#'
#' @noRd
read_fallback <- function(mkt_index) {
  this_fallback_file <- system.file(
    stringr::str_glue("extdata/fallback-indices/{mkt_index}.rds"),
    package = "yfR"
  )

  df_index <- readr::read_rds(this_fallback_file)
  fallback_date <- df_index$fetched_at[1]

  cli::cli_alert_success(
    "Using fallback {mkt_index} composition from {fallback_date}"
  )

  return(df_index)
}

#' Get available indices in package
#'
#' This function will return all available market indices that are registered
#' in the package.
#'
#' @param print_description Logical (TRUE/FALSE) - flag for printing description of
#' available indices/collections
#'
#' @return A vector of mkt indices
#' @export
#'
#' @examples
#'
#' indices <- yf_index_list()
#' indices
yf_index_list <- function(print_description = FALSE) {
  available_indices <- c("SP500", "IBOV", "FTSE",
                         "DOW",
                         "testthat-collection")

  df_indices <- dplyr::tibble(
    available_indices,
    description = c(
      "The SP500 index (US MARKET) - Ticker = ^GSPC",
      "The Ibovespa index (BR MARKET) - Ticker = ^BVSP",
      "The FTSE index (UK MARKET) - Ticker = ^FTSE",
      "The DOW index (US MARKET) - Ticker = ^DJI",
      "A (small) testing index for testthat() -- dev stuff, dont use it!"
    )
  )

  if (print_description) {
    cli::cli_h2("Description of Available Collections")

    for (i_row in 1:nrow(df_indices)) {
      cli::cli_alert_info(
        "{df_indices$available_indices[i_row]}: {df_indices$description[i_row]}"
      )

    }
  }

  return(invisible(available_indices))
}

#' Function to download the current components of the
#' FTSE100 index from Wikipedia
#' @noRd
yf_index_ftse <- function(do_cache = TRUE,
                               cache_folder = yf_cachefolder_get()) {
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
  df_ftse <- my_url %>%
    rvest::read_html() %>%
    rvest::html_nodes(xpath = my_xpath) %>%
    rvest::html_table()

  df_ftse <- df_ftse[[1]]

  df_ftse <- df_ftse %>%
    dplyr::rename(
      ticker = EPIC,
      company = Company,
      sector = names(df_ftse)[3]
    ) %>%
    dplyr::mutate(
      index = "FTSE",
      index_ticker = "^FTSE"
    )

  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_ftse, cache_file)
  }

  yf_index_format_msg("FTSE", nrow(df_ftse))

  return(df_ftse)
}

#' Function to download the current components of the
#' Ibovespa index from B3 website
#' @noRd
yf_index_ibov <- function(do_cache = TRUE,
                               cache_folder = yf_cachefolder_get(),
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

    df_ibov_comp <- rvest::read_html(my_url) %>%
      rvest::html_table()

    df_ibov_comp <- df_ibov_comp[[1]]

    Sys.sleep(0.5)

    if (nrow(df_ibov_comp) > 0) break()
  }

  df_ibov_comp <- df_ibov_comp %>%
    dplyr::rename(ticker = Ticker,
                  company = Company,
                  industry = Industry) %>%
    dplyr::mutate(type_stock = NA,
                  quantity = NA,
                  percentage_participation = NA,
                  ref_date = Sys.Date(),
                  index = "IBOV",
                  index_ticker = "^BVSP") %>%
    dplyr::select(-Headquarters)

  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_ibov_comp, cache_file)
  }

  yf_index_format_msg("Ibovespa", nrow(df_ibov_comp))

  return(df_ibov_comp)
}

#' Function for fetching test tickers
#' @noRd
yf_index_test <- function(do_cache = TRUE,
                               cache_folder = yf_cachefolder_get()) {

  df_test <- dplyr::tibble(
    ticker = c("^GSPC", "^FTSE"),
    index_ticker = "^GSPC" # simply keep it there for placeholder
  )

  return(df_test)
}

#' Function to download the current components of the SP500 index from Wikipedia
#' @noRd
yf_index_sp500 <- function(do_cache = TRUE,
                                cache_folder = yf_cachefolder_get()) {
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
  df_sp500 <- my_url %>%
    rvest::read_html() %>%
    rvest::html_nodes(xpath = my_xpath) %>%
    rvest::html_table(fill = TRUE)

  df_sp500 <- df_sp500[[1]]

  df_sp500 <- df_sp500  %>%
    dplyr::rename(
      ticker = Symbol,
      company = Security,
      sector = `GICS Sector`
    ) %>%
    dplyr::select(ticker, company, sector) %>%
    dplyr::mutate(
      index = "SP500",
      index_ticker = "^GSPC"
    )


  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_sp500, cache_file)
  }

  yf_index_format_msg("SP500", nrow(df_sp500))
  return(df_sp500)
}

#' Function to download the current components of the dOW index from Wikipedia
#' @noRd
yf_index_dow <- function(do_cache = TRUE,
                           cache_folder = yf_cachefolder_get()) {
  cache_file <- file.path(
    cache_folder,
    paste0("DOW30_Composition_", Sys.Date(), ".rds")
  )

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df_dow <- readr::read_rds(cache_file)
      return(df_dow)
    }
  }

  my_url <- "https://en.wikipedia.org/wiki/Dow_Jones_Industrial_Average#Components"

  read_html <- 0 # fix for global variable nagging from BUILD
  my_xpath <- '//*[@id="constituents"]'
  df_dow <- my_url %>%
    rvest::read_html() %>%
    rvest::html_nodes(xpath = my_xpath) %>%
    rvest::html_table(fill = TRUE)

  df_dow <- df_dow[[1]]

  df_dow <- df_dow  %>%
    dplyr::rename(
      ticker = Symbol,
      company = Company,
      sector = Industry
    ) %>%
    dplyr::select(ticker, company, sector) %>%
    dplyr::mutate(
      index = "DOW",
      index_ticker = "^DJI"
    )


  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_dow, cache_file)
  }

  yf_index_format_msg("DOW", nrow(df_dow))

  return(df_dow)
}


#' Builds index message
#' @noRd
yf_index_format_msg <- function(index_in, my_n) {
  cli::cli_alert_success("Got {index_in} composition with {my_n} rows")
  return(invisible(TRUE))
}
