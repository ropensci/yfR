library(testthat)
library(yfR)

# test data in all indices
available_indices <- yf_get_available_indices()

for (i_index in available_indices) {

  test_that(
    stringr::str_glue("Test of yf_get_index_comp() for {i_index}"), {

      skip_if_offline()
      skip_on_cran() # too heavy for cran

      expect_true(tibble::is_tibble(yf_get_index_comp(i_index)))

      }
  )

  Sys.sleep(1)

}


# parallel test for collections
n_workers <- floor(parallel::detectCores()/2)
future::plan(future::multisession, workers = n_workers)
available_collections <- yf_get_available_collections()

for (i_collection in available_collections) {

  test_that(desc = "Test of yf_get_collection() for {i_collection}", {

    skip_if_offline()
    skip_on_cran() # too heavy for cran

    df <- yf_get_collection(collection = i_collection,
                            first_date = Sys.Date() - 30,
                            last_date = Sys.Date(),
                            do_parallel = TRUE)

    expect_true(nrow(df) > 0)

  })

}

