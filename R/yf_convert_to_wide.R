#' Transforms a dataframe in the long format to a list of dataframes in the wide format
#'
#' @param df_in Dataframe in the long format (probably the output of yf_get_data())
#'
#' @return A list with dataframes in the wide format (each element is a different column)
#' @export
#'
#' @examples
#'
#' my_f <- system.file( 'extdata/example_data_yfR.rds', package = 'yfR' )
#' df_tickers <- readRDS(my_f)
#' l_wide <- yf_converto_to_wide(df_tickers)
#' l_wide
yf_converto_to_wide <- function(df_in) {

  cols_to_keep <- c('ref_date', 'ticker')

  my_cols <- setdiff(names(df_in), cols_to_keep)

  fct_format_wide <- function(name_in, df_in) {

    temp_df <- df_in[, c('ref_date', 'ticker', name_in)]

    temp_df_wide <- tidyr::spread(temp_df, ticker, name_in)
    return(temp_df_wide)

  }

  l_out <- lapply(my_cols, fct_format_wide, df_in = df_in)
  names(l_out) <- my_cols

  return(l_out)

}
