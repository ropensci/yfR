library(testthat)
library(yfR)


test_that(desc = "Test of yf_get_data() - is df?", {

  skip_if(!curl::has_internet())

  my_tickers <- c("^GSPC")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_cache = FALSE
  )

  expect_true(is.data.frame(df))

})

test_that(desc = "Test of yf_get_data() - nrow > 0", {

  skip_if(!curl::has_internet())

  my_tickers <- c("^BVSP")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_cache = FALSE
  )

  expect_true(nrow(df) > 0)

})

