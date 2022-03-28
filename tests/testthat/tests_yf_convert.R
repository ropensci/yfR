library(testthat)
library(yfR)

test_that(desc = "Test of yf_convert_to_wide()", {

  skip_if_offline()
  skip_on_cran()

  my_tickers <- c("^GSPC", "^BVSP")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date()
  )

  l_out <- yf_converto_to_wide(df)

  expect_true(length(l_out) > 1)
})

