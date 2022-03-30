library(testthat)
library(yfR)

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

