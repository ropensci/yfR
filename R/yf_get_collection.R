#' Downloads collection of data from Yahoo Finance
#'
#' This function will use a preestablished collection data, such as index components and
#' will downloads all data from Yahoo Finance using \code{\link{yf_get_data}}.
#'
#' @param collection A collection to fetch data (e.g. "SP500", "IBOV", "FTSE" )
#' @inheritParams yf_get_data
#'
#' @return A dataframe with financial prices from collection
#' @export
#'
#' @examples
#' \dontrun{
#' df_yf <- yf_get_collection("IBOV")
#' }
#'
yf_get_collection <- function(collection,
                              first_date = Sys.Date() - 15,
                              last_date = Sys.Date(),
                              do_cache = TRUE,
                              cache_folder = yf_get_default_cache_folder()) {
  av_collections <- yf_get_available_collections()
  if (!collection %in% av_collections) {
    stop(
      "Check input collection. Available collections are ",
      paste0(av_collections, collapse = ", ")
    )
  }

  df_collection <- yf_get_index_comp(mkt_index = collection)

  # fix tickers
  if (collection == "IBOV") {
    # all ibov tickers finish with .SA
    my_tickers <- stringr::str_c(df_collection$ticker, ".SA")
  } else {
    my_tickers <- df_collection$ticker
  }

  # fetch data
  df_yf <- yf_get_data(
    tickers = my_tickers,
    first_date = first_date,
    last_date = last_date,
    do_cache = do_cache,
    cache_folder = cache_folder
  )

  return(df_yf)
}


yf_get_available_collections <- function() {
  available_indices <- yf_get_available_indices()

  return(available_indices)
}
