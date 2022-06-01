library(testthat)
library(yfR)

test_that("Test of yf_get_available_indices()", {

  available_indices <- yf_get_available_indices()

  expect_true(class(available_indices) == 'character')
})

testhat_index_comp <- function(df_in) {

  expect_true(tibble::is_tibble(df_in))
  expect_true(nrow(df_in) > 0)
}

test_that("Test of yf_get_index_comp() -- using web", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  available_indices <- yf_get_available_indices()

  for (i_index in available_indices) {

    df_index <- yf_get_index_comp(i_index,
                                  force_fallback = FALSE)
    testhat_index_comp(df_index)

  }

})

test_that("Test of yf_get_index_comp() -- using fallback files", {

  available_indices <- yf_get_available_indices()

  for (i_index in available_indices) {

    df_index <- yf_get_index_comp(i_index,
                                  force_fallback = TRUE)
    testhat_index_comp(df_index)


  }

})


test_that("Test of yf_collection_get() -- single session", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  # parallel test for collections
  to_test_collection <- "testthat-collection"

  df <- yf_collection_get(collection = to_test_collection,
                          first_date = Sys.Date() - 30,
                          last_date = Sys.Date(),
                          do_parallel = FALSE)

  expect_true(nrow(df) > 0)

})

test_that("Test of yf_collection_get() -- multi-session", {

  # 20220501 yf now sets api limits, which invalidates any parallel computation
  skip(
    paste0("Skipping since parallel is not supported due to YF api limits, ",
           "and collections are large datasets for single session download.")
  )

  # parallel test for collections
  n_workers <- floor(parallel::detectCores()/2)
  future::plan(future::multisession, workers = n_workers)
  available_collections <- yf_get_available_collections()


  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  for (i_collection in available_collections) {

    df <- yf_collection_get(collection = i_collection,
                            first_date = Sys.Date() - 30,
                            last_date = Sys.Date(),
                            do_parallel = TRUE)

    expect_true(nrow(df) > 0)

  }

})
