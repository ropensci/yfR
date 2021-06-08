#' Function to download the current components of the SP500 index from Wikipedia
#'
#' This function scrapes the stocks that constitute the SP500 index from the wikipedia page at https://en.wikipedia.org/wiki/List_of_S%26P_500_companies.
#'
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe that includes a column with the list of tickers of companies that belong to the SP500 index
#' @export
#' @import rvest
#' @examples
#' \dontrun{
#' df.SP500 <- GetSP500Stocks()
#' print(df.SP500$tickers)
#' }
GetSP500Stocks <- function(do.cache = TRUE,
                           cache.folder = file.path(tempdir(),
                                                    'BGS_Cache')){

  cache.file <- file.path(cache.folder,
                          paste0('SP500_Composition_', Sys.Date(), '.rds') )

  if (do.cache) {
    # check if file exists
    flag <- file.exists(cache.file)

    if (flag) {
      df.SP500Stocks <- readRDS(cache.file)
      return(df.SP500Stocks)
    }
  }

    my.url <- 'https://en.wikipedia.org/wiki/List_of_S%26P_500_companies'

  read_html <- 0 # fix for global variable nagging from BUILD
  my.xpath <- '//*[@id="constituents"]'
  df.SP500Stocks <- my.url %>%
    read_html() %>%
    html_nodes(xpath = my.xpath) %>%
    html_table(fill = TRUE)

  df.SP500Stocks <- df.SP500Stocks[[1]]

  colnames(df.SP500Stocks) <- c('Tickers','Company','SEC.filings','GICS.Sector',
                                'GICS.Sub.Industry','HQ.Location','Date.First.Added','CIK', 'Founded')

  if (do.cache) {
    if (!dir.exists(cache.folder)) dir.create(cache.folder)

    saveRDS(df.SP500Stocks, cache.file)

  }

  return(df.SP500Stocks)
}
