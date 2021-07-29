library(testthat)
library(yfR)

test_that(desc = "Test of yf_convert_to_wide()", {

  skip_if(!curl::has_internet())

  my_tickers <- c("^GSPC", "^BVSP")

  df <- yf_get_data(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date()
  )

  l_out <- yf_converto_to_wide(df)

  expect_true(length(l_out) > 1)
})

# test for indices
available_indices <- yf_get_available_indices()

for (i_index in available_indices) {

  test_that(desc = stringr::str_glue("Test of yf_get_index_comp() for {i_index}"), {
    expect_true(is.data.frame(yf_get_index_comp(i_index)))
  })

  Sys.sleep(1)

}
