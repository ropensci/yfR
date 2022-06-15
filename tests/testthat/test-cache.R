library(testthat)
library(yfR)

test_that(desc = "Test of cache", {

  expect_true(is.character(yf_cachefolder_get()))

})
