yf_get_index_comp <- function(mkt_index,
                              do_cache = TRUE,
                              cache_folder = yf_get_default_cache_folder()) {

  available_indices <- yf_get_available_indices()
  if (!any(mkt_index %in% available_indices)) {
    stop(stringr::str_glue('Index {mkt_index} is no available within the options: ',
                           ' {paste0(available_indices, collapse = ", ")}'))
  }

  if (mkt_index == 'IBOV') {
    df_index <- yf_get_ibov_stocks(do_cache = do_cache,
                                   cache_folder = cache_folder,
                                   max_tries  = 10)

  }

  if (mkt_index == 'SP500') {
    df_index <- yf_get_sp500_stocks()
  }

}

yf_get_available_indices <- function() {
  available_indices <- c('SP500', 'IBOV', 'FTSE100')

  return(available_indices)
}

yf_get_default_cache_folder <- function() {
  path_cache <- file.path(tempdir(), 'BGS_Cache')
  return(path_cache)
}

#' Function to download the current components of the Ibovespa index from B3 website
#'
#' This function scrapes the stocks that constitute the Ibovespa index from the wikipedia page at http://bvmf.bmfbovespa.com.br/indices/ResumoCarteiraTeorica.aspx?Indice=IBOV&idioma=pt-br.
#'
#' @param max_tries Maximum number of attempts to download the data
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe that includes a column with the list of tickers of companies that belong to the Ibovespa index
#' @export
#' @examples
#' \dontrun{
#' df.ibov <- GetIbovStocks()
#' print(df.ibov$tickers)
#' }
yf_get_ibov_stocks <- function(do_cache = TRUE,
                               cache_folder = file.path(tempdir(),
                                                        'BGS_Cache'),
                               max_tries  = 10){

  cache_file <- file.path(cache_folder,
                          paste0('Ibov_Composition_', Sys.Date(), '.rds') )
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
    myUrl <- 'http://bvmf.bmfbovespa.com.br/indices/ResumoCarteiraTeorica.aspx?Indice=IBOV&idioma=pt-br'
    #df_ibov_comp <- XML::readHTMLTable(myUrl)[[1]]
    df_ibov_comp <- as.data.frame(XML::readHTMLTable(myUrl))

    Sys.sleep(0.5)

    if (nrow(df_ibov_comp) > 0) break()

  }

  names(df_ibov_comp) <- c('ticker', 'company', 'type_stock',
                           'quantity', 'percentage_participation')

  df_ibov_comp$quantity <- as.numeric(stringr::str_replace_all(df_ibov_comp$quantity,
                                                               stringr::fixed('.'), ''))
  df_ibov_comp$percentage_participation <- as.numeric(stringr::str_replace_all(df_ibov_comp$percentage_participation,
                                                                               stringr::fixed(','), '.'))

  df_ibov_comp$ref.date <- Sys.Date()
  df_ibov_comp$ticker <- as.character(df_ibov_comp$ticker)
  df_ibov_comp$index <- 'IBOV'

  if (do_cache) {

    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_ibov_comp, cache_file)
  }

  yf_get_message_index('Ibovespa', nrow(df_ibov_comp))

  return(df_ibov_comp)
}


#' Function to download the current components of the FTSE100 index from Wikipedia
#'
#' This function scrapes the stocks that constitute the FTSE100 index from the wikipedia page at <https://en.wikipedia.org/wiki/FTSE_100_Index#List_of_FTSE_100_companies>.
#'
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe that includes a column with the list of tickers of companies that belong to the FTSE100 index
#' @export
#' @import rvest
#' @examples
#' \dontrun{
#' df.FTSE100 <- GetFTSE100Stocks()
#' print(df.FTSE100$tickers)
#' }
GetFTSE100Stocks <- function(do_cache = TRUE,
                             cache_folder = file.path(tempdir(),
                                                      'BGS_Cache')){

  cache_file <- file.path(cache_folder,
                          paste0('FTSE100_Composition_', Sys.Date(), '.rds') )

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df.FTSE100Stocks <- readRDS(cache_file)
      return(df.FTSE100Stocks)
    }
  }

  my.url <- 'https://en.wikipedia.org/wiki/FTSE_100_Index'

  read_html <- 0 # fix for global variable nagging from BUILD
  my.xpath <- '//*[@id="mw-content-text"]/div/table[2]' # old xpath
  my.xpath <- '//*[@id="constituents"]'
  df.FTSE100Stocks <- my.url %>%
    read_html() %>%
    html_nodes(xpath = my.xpath) %>%
    html_table()

  df.FTSE100Stocks <- df.FTSE100Stocks[[1]]

  colnames(df.FTSE100Stocks) <- c('company','tickers','ICB.sector')

  if (do_cache) {

    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    saveRDS(df.FTSE100Stocks, cache_file)
  }

  return(df.FTSE100Stocks)
}

#' Function to download the current components of the SP500 index from Wikipedia
#'
#' This function scrapes the stocks that constitute the SP500 index from the wikipedia page at https://en.wikipedia.org/wiki/List_of_S%26P_500_companies.
#'
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe that includes a column with the list of tickers of companies that belong to the SP500 index
#' @export
#' @import rvest dplyr
yf_get_sp500_stocks <- function(do_cache = TRUE,
                                cache_folder = file.path(tempdir(),
                                                         'BGS_Cache')){

  cache_file <- file.path(cache_folder,
                          paste0('SP500_Composition_', Sys.Date(), '.rds') )

  if (do_cache) {
    # check if file exists
    flag <- file.exists(cache_file)

    if (flag) {
      df_sp500 <- readr::read_rds(cache_file)
      return(df_sp500)
    }
  }

  my_url <- 'https://en.wikipedia.org/wiki/List_of_S%26P_500_companies'

  read_html <- 0 # fix for global variable nagging from BUILD
  my_xpath <- '//*[@id="constituents"]'
  df_sp500 <- my_url %>%
    read_html() %>%
    html_nodes(xpath = my_xpath) %>%
    html_table(fill = TRUE)

  df_sp500 <- df_sp500[[1]]

  df_sp500 <- df_sp500  |>
    dplyr::rename(ticker = Symbol,
                  company = Security,
                  sector = `GICS Sector`) |>
    dplyr::select(ticker, company, sector)


  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder)

    readr::write_rds(df_sp500, cache_file)

  }

  yf_get_message_index('SP500', nrow(df_sp500))
  return(df_sp500)
}


