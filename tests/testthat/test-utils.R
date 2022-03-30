library(testthat)
library(yfR)


test_that(desc = "Test of fix_ticker_name", {

  my_tickers <- c("^GSPC")

  new_tickers <- fix_ticker_name(my_tickers)

  flag <- stringr::str_detect(new_tickers,
                              stringr::fixed('^'))

  expect_false(flag)

})

test_that(desc = "Test of get_morale_boost()", {

  my_msg <- get_morale_boost()

  expect_true(class(my_msg)[2] == "character")

})

test_that(desc = "Test of date_to_unix()", {

  numdate <- date_to_unix(Sys.Date())

  expect_true(class(numdate) == "numeric")

})


test_that(desc = "Test of unix_to_date()", {

  date <- unix_to_date(0)

  expect_true(class(date) == "Date")
  expect_true(date == as.Date("1970-01-01"))

})


test_that(desc = "Test of calc_ret()", {

  P <- runif(100)

  r <- calc_ret(P)

  expect_true(class(r) == "numeric")
  expect_true( P[2]/P[1] -1 == r[2])

})

test_that(desc = "Test of set_cli_msg()", {

  my_msg <- set_cli_msg("hey, im a message")

  expect_true(class(my_msg) == "character")

})
