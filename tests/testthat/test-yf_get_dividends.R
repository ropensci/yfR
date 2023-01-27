library(testthat)
library(yfR)

# Functions for testing output from calls to yf_get
test_df <- function(df) {

  testthat::expect_true(tibble::is_tibble(df))
  testthat::expect_false(dplyr::is_grouped_df(df))
  testthat::expect_true(nrow(df) > 0)

  return(invisible(TRUE))
}


test_that(desc = "Test of yf_get_dividends()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  df_live <- yf_get_dividends(ticker = "VALE3.SA",
                              first_date = "2000-01-01",
                              last_date = "2023-01-01")

  test_df(df_live)

})

