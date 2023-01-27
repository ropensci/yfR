library(testthat)
library(yfR)

# Functions for testing output from calls to yf_get
test_df <- function(df) {

  testthat::expect_true(tibble::is_tibble(df))
  testthat::expect_false(dplyr::is_grouped_df(df))
  testthat::expect_true(nrow(df) > 0)

  return(invisible(TRUE))
}


test_that(desc = "Test of yf_live_prices()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_ticker <- "^GSPC"

  df_live <- yf_live_prices(my_ticker)

  test_df(df_live)

})
