library(testthat)
library(yfR)

# Functions for testing output from calls to yf_get_data
test_yf_output <- function(df_yf, tickers) {

  testthat::expect_true(tibble::is_tibble(df_yf))
  testthat::expect_false(dplyr::is_grouped_df(df_yf))
  testthat::expect_true(nrow(df_yf) > 0)
  testthat::expect_true(dplyr::n_distinct(df_yf$ticker) == length(tickers))

  # check df_control
  df_control <- attributes(df_yf)$df_control
  testthat::expect_true(tibble::is_tibble(df_control))

  return(invisible(TRUE))
}


test_that(desc = "Test of yf_get_data()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^GSPC", "^BVSP")

  # vanilla call
  df_yf <- yf_get_data(
    tickers = my_tickers
  )

  test_yf_output(df_yf, my_tickers)

  # with cache
  df_yf <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 60,
    last_date = Sys.Date() - 30,
    do_cache = TRUE
  )

  test_yf_output(df_yf, my_tickers)

  # with cache (again, for testing caching system and
  # handling of missing portions of data)
  df_yf <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 90,
    last_date = Sys.Date(),
    do_cache = TRUE
  )

  test_yf_output(df_yf, my_tickers)

  # with do_complete_data = TRUE
  df_yf <- yf_get_data(
    tickers = my_tickers,
    do_complete_data = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})

test_that(desc = "Test of yf_get_data(): do_parallel = TRUE", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  # detect cores and skip if < 2
  n_cores <- parallel::detectCores()

  if (n_cores < 2) {
    skip('Not enough cores for parallel computations (< 2)')
  }

  future::plan(future::multisession,
               workers = floor(n_cores/2))

  my_tickers <- c("^BVSP", "^GSPC", 'FB',
                  "MMM", "GM", "AAPL")

  df_yf <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_parallel = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})


test_that(desc = "Test of yf_get_data(): aggregations", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^BVSP", "^GSPC")

  possible_freq <- c('daily', 'weekly', 'monthly', 'yearly')
  possible_agg <- c('first', 'last')

  df_grid <- tidyr::expand_grid(possible_freq,
                                possible_agg)

  for (i_test in seq(1, nrow(df_grid))) {

    tickers = my_tickers
    first_date = Sys.Date() - 500
    last_date = Sys.Date()
    freq_data = df_grid$possible_freq[i_test]
    how_to_aggregate = df_grid$possible_agg[i_test]

    df_yf <- yf_get_data(
      tickers = tickers,
      first_date = first_date,
      last_date = last_date,
      freq_data = freq_data,
      how_to_aggregate = how_to_aggregate
    )

    test_yf_output(df_yf, my_tickers)
  }

})


test_that(desc = "Test of yf_get_data(): be_quiet", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^BVSP")

  df_yf <- yf_get_data(
    tickers = my_tickers,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})
