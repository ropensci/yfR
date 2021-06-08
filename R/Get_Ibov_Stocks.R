#' Function to download the current components of the Ibovespa index from Bovespa website
#'
#' This function scrapes the stocks that constitute the Ibovespa index from the wikipedia page at http://bvmf.bmfbovespa.com.br/indices/ResumoCarteiraTeorica.aspx?Indice=IBOV&idioma=pt-br.
#'
#' @param max.tries Maximum number of attempts to download the data
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe that includes a column with the list of tickers of companies that belong to the Ibovespa index
#' @export
#' @examples
#' \dontrun{
#' df.ibov <- GetIbovStocks()
#' print(df.ibov$tickers)
#' }
GetIbovStocks <- function(do.cache = TRUE,
                          cache.folder = file.path(tempdir(),
                                                   'BGS_Cache'),
                          max.tries  = 10){

  cache.file <- file.path(cache.folder,
                          paste0('Ibov_Composition_', Sys.Date(), '.rds') )

  # get list of ibovespa's tickers from wbsite

  if (do.cache) {
    # check if file exists
    flag <- file.exists(cache.file)

    if (flag) {
      df.ibov.comp <- readRDS(cache.file)
      return(df.ibov.comp)
    }
  }

  for (i.try in seq(max.tries)) {
    myUrl <- 'http://bvmf.bmfbovespa.com.br/indices/ResumoCarteiraTeorica.aspx?Indice=IBOV&idioma=pt-br'
    #df.ibov.comp <- XML::readHTMLTable(myUrl)[[1]]
    df.ibov.comp <- as.data.frame(XML::readHTMLTable(myUrl))

    Sys.sleep(0.5)

    if (nrow(df.ibov.comp) > 0) break()

  }

  names(df.ibov.comp) <- c('tickers', 'ticker.desc', 'type.stock', 'quantity', 'percentage.participation')

  df.ibov.comp$quantity <- as.numeric(stringr::str_replace_all(df.ibov.comp$quantity,
                                                               stringr::fixed('.'), ''))
  df.ibov.comp$percentage.participation <- as.numeric(stringr::str_replace_all(df.ibov.comp$percentage.participation,
                                                                               stringr::fixed(','), '.'))

  df.ibov.comp$ref.date <- Sys.Date()
  df.ibov.comp$tickers <- as.character(df.ibov.comp$tickers)

  if (do.cache) {

    if (!dir.exists(cache.folder)) dir.create(cache.folder)

    saveRDS(df.ibov.comp, cache.file)
  }

  return(df.ibov.comp)
}

