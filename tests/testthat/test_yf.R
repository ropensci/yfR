library(testthat)
library(yfR)

# test for indices
available_indices <- yf_get_available_indices()
for (i_index in available_indices) {
  test_that(desc = stringr::str_glue("Test of yf_get_index_comp() for {i_index}"), {
    expect_true(is.data.frame(yf_get_index_comp(i_index)))
  })
}


test_that(desc = "Test of yf_get_data()", {
  my_tickers <- c("^GSPC")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date()
  )

  expect_true(is.data.frame(df))
})


test_that(desc = "Test of yf_convert_to_wide()", {
  my_tickers <- c("^GSPC", "FB")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date()
  )

  l_out <- yf_converto_to_wide(df)

  expect_true(length(l_out) > 1)
})


#' my_f <- system.file( 'extdata/example_data_yfR.rds', package = 'yfR' )
#' df_tickers <- readRDS(my_f)
#' l_wide <- yf_converto_to_wide(df_tickers)
#' l_wide
