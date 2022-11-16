## -----------------------------------------------------------------------------
available_collections <- yfR::yf_get_available_collections(
  print_description = TRUE
  )

available_collections

## ---- eval=FALSE--------------------------------------------------------------
#  library(yfR)
#  
#  # be patient, it takes a while
#  df_yf <- yf_collection_get("SP500")
#  
#  head(df_yf)

