library(testthat)
library(yf)

# test for indices
available_indices <- yf_get_available_indices()
for (i_index in available_indices) {
  test_that(desc = stringr::str_glue('Test of {i_index}'),{
    expect_true(is.data.frame(yf_get_index_comp(i_index))) } )
}


my_tickers <- c('MMM')

test_that(desc = stringr::str_glue('Test of main fct'),{
  l.out <- yf_get_data(tickers = my_tickers,
                       first_date = Sys.Date()-30,
                       last_date = Sys.Date())

  expect_true(is.list(l.out))})

