library(testthat)
library(yfR)

test_that(desc = "Test of cache", {

  expect_true(is.character(yf_get_default_cache_folder()))

})
