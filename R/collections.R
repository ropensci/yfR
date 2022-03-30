#' Downloads a collection of data from Yahoo Finance
#'
#' This function will use a set collection of YF data, such as index components
#' and will download all data from Yahoo Finance using \code{\link{yf_get}}.
#'
#' @param collection A collection to fetch data (e.g. "SP500", "IBOV", "FTSE" ).
#'   See function \code{\link{yf_get_available_collections}} for finding all
#'   available collections
#' @inheritParams yf_get
#'
#' @return A dataframe with financial prices from collection
#' @export
#'
#' @examples
#'
#' \dontrun{
#' df_yf <- yf_collection_get("IBOV")
#' }
#'
yf_collection_get <- function(collection,
                              first_date = Sys.Date() - 15,
                              last_date = Sys.Date(),
                              do_parallel = FALSE,
                              do_cache = TRUE,
                              cache_folder = yf_get_default_cache_folder()) {

  cli::cli_h1('Fetching price collection for {collection}')

  av_collections <- yf_get_available_collections()
  if (!collection %in% av_collections) {
    stop(
      "Check input collection. Available collections are ",
      paste0(av_collections, collapse = ", ")
    )
  }

  df_collection <- yf_get_index_comp(mkt_index = collection)

  ticker_index <- df_collection$index_ticker[1]

  # fix tickers for BR/IBOV
  if (collection == "IBOV") {

    # all ibov tickers finish with .SA
    my_tickers <- stringr::str_c(df_collection$ticker, ".SA")

  } else {

    my_tickers <- df_collection$ticker

  }

  # ok, now fetch data for collection
  df_yf <- yf_get(
    tickers = my_tickers,
    first_date = first_date,
    last_date = last_date,
    do_cache = do_cache,
    do_parallel = do_parallel,
    bench_ticker = ticker_index,
    cache_folder = cache_folder
  )

  return(df_yf)
}


#' Returns available collections
#'
#' @return A string vector with available collections
#' @export
#'
#' @examples
#' yf_get_available_collections()
yf_get_available_collections <- function() {
  available_indices <- yf_get_available_indices()

  return(available_indices)
}
