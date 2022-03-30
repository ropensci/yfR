#' Transforms a long (stacked) dataframe into a list of wide dataframes
#'
#' @param df_in dataframe in the long format (probably the output of yf_get())
#'
#' @return A list with dataframes in the wide format (each element is a
#'   different column)
#' @export
#'
#' @examples
#'
#' my_f <- system.file("extdata/example_data_yfR.rds", package = "yfR")
#' df_tickers <- readRDS(my_f)
#' l_wide <- yf_convert_to_wide(df_tickers)
#' l_wide
yf_convert_to_wide <- function(df_in) {
  cols_to_keep <- c("ref_date", "ticker")

  my_cols <- setdiff(names(df_in), cols_to_keep)

  fct_format_wide <- function(name_in, df_in) {

    temp_df <- df_in[, c("ref_date", "ticker", name_in)]

    # make sure data points are unique
    # always fetch first ocurrence
    temp_df <- unique(temp_df)




    temp_df_wide <- tidyr::pivot_wider(
      data = temp_df,
      names_from = ticker,
      values_from = tidyr::all_of(name_in)
      )

    return(temp_df_wide)

  }

  l_out <- lapply(my_cols,
                  fct_format_wide,
                  df_in = df_in)
  names(l_out) <- my_cols

  return(l_out)
}
