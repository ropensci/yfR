library(testthat)
library(yfR)

max_tickers_dl = 100

test_yf_indices_output <- function(df_yf, tickers) {

  testthat::expect_true(tibble::is_tibble(df_yf))
  testthat::expect_false(dplyr::is_grouped_df(df_yf))
  testthat::expect_true(nrow(df_yf) > 0)

  n_requested <- length(tickers)
  diff_tickers <- (n_requested - dplyr::n_distinct(df_yf$ticker))/n_requested

  # at least 80% of tickers
  testthat::expect_true(diff_tickers < 0.20)

  # check df_control
  df_control <- attributes(df_yf)$df_control
  testthat::expect_true(tibble::is_tibble(df_control))

  return(invisible(TRUE))
}

test_that("Test of yf_get_available_indices()", {

  available_indices <- yf_get_available_indices()

  expect_true(class(available_indices) == 'character')
})

test_that("Test of yf_get_index_comp()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  available_indices <- yf_get_available_indices()

  for (i_index in available_indices) {

    expect_true(tibble::is_tibble(yf_get_index_comp(i_index)))

  }

})


test_that("Test of yf_collection_get()", {

  # 20220501 yf now sets api limits, which invalidates any parallel computation
  # 2220522 now getSymbols uses json endpoint (not limited, so far)

  # skip(
  #   paste0("Skipping since parallel is not supported due to YF api limits, ",
  #          "and collections are large datasets for single session download.")
  # )

  # parallel test for collections
  n_workers <- floor(parallel::detectCores()/2)
  future::plan(future::multisession, workers = n_workers)
  available_collections <- yf_get_available_collections()

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  for (i_collection in available_collections) {

    df_collection <- yf_get_index_comp(i_collection)

    # skip if too many tickers
    if (dplyr::n_distinct(df_collection$ticker) > max_tickers_dl) {
      skip(stringr::str_glue("too many tickers to download for {i_collection}, ",
                             "best to skip this download.. "))
    }

    df <- yf_collection_get(collection = i_collection,
                            first_date = Sys.Date() - 30,
                            last_date = Sys.Date(),
                            do_parallel = TRUE)

    test_yf_indices_output(df, df_collection$ticker)

  }

})

