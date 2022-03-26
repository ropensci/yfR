library(testthat)
library(yfR)

test_that(desc = 'Test of yf_get_available_indices', {

  available <- yf_get_available_indices()
  expect_true(length(available) > 0)

})

yf_get_available_collections <- function() {
  available_indices <- yf_get_available_indices()

  return(available_indices)
}

test_that(desc = "Test of yf_get_collection() - nrow > 0?", {

  skip_if_offline()
  skip_on_cran() # too heavy for cran

  my_collection <- "IBOV"

  df <- yf_get_collection(collection = my_collection,
                          first_date = Sys.Date() - 10,
                          last_date = Sys.Date())

  expect_true(nrow(df) > 0)

})
