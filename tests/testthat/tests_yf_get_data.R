library(testthat)
library(yfR)

test_that(desc = "Test of yf_get_data() - is df?", {

  skip_if_offline()
  skip_on_cran() # too heavy for cran

  my_tickers <- c("^GSPC")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_cache = FALSE
  )

  expect_true(tibble::is_tibble(df))

})

test_that(desc = "Test of yf_get_data() - nrow > 0", {

  skip_if_offline()
  skip_on_cran() # too heavy for cran

  my_tickers <- c("^BVSP")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_cache = FALSE
  )

  expect_true(nrow(df) > 0)

})

test_that(desc = "Test of yf_get_data() args: do_complete_data = TRUE", {

  skip_if_offline()
  skip_on_cran() # too heavy for cran

  my_tickers <- c("^BVSP", "^GSPC")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_complete_data = TRUE,
    do_cache = FALSE
  )

  expect_true(nrow(df) > 0)

})

test_that(desc = "Test of yf_get_data() args: do_parallel = TRUE", {

  skip_if_offline()
  skip_on_cran()

  # detect cores and skip if < 2
  n_cores <- parallel::detectCores()

  if (n_cores < 2) {
    skip()
  }

  future::plan(future::multisession,
               workers = floor(n_cores/2))

  my_tickers <- c("^BVSP", "^GSPC", 'FB',
                  "MMM", "GM", "AAPL")


  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_parallel = TRUE,
    do_cache = FALSE
  )

  expect_true(nrow(df) > 0)

})
