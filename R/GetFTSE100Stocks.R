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
GetFTSE100Stocks <- function(do.cache = TRUE,
                             cache.folder = file.path(tempdir(),
                                                      'BGS_Cache')){

  cache.file <- file.path(cache.folder,
                          paste0('FTSE100_Composition_', Sys.Date(), '.rds') )

  if (do.cache) {
    # check if file exists
    flag <- file.exists(cache.file)

    if (flag) {
      df.FTSE100Stocks <- readRDS(cache.file)
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

  if (do.cache) {

    if (!dir.exists(cache.folder)) dir.create(cache.folder)

    saveRDS(df.FTSE100Stocks, cache.file)
  }

  return(df.FTSE100Stocks)
}
