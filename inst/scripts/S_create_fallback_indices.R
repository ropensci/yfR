available <- yfR::yf_index_list()

for (i_available in available) {
  df <- yfR::yf_index_composition(i_available)

  df$fetched_at <- Sys.Date()

  this_file <- fs::path(
    'inst/extdata/fallback-indices/',
    stringr::str_glue("{i_available}.rds")
  )
  readr::write_rds(df,
            file = this_file)
}
