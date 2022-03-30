library(testthat)
library(yfR)

test_that(desc = "Test of yf_convert_to_wide()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^GSPC", "^BVSP")

  df <- yf_get(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date()
  )

  l_out <- yf_convert_to_wide(df)

  expect_true(length(l_out) > 1)
  expect_true(tibble::is_tibble(l_out[[1]]))
})

