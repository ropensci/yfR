#' Returns the default folder for caching
#'
#' By default, yfR uses a temp dir to store files.
#'
#' @return a path (string)
#' @export
#'
#' @examples
#' print(yf_get_default_cache_folder())
yf_get_default_cache_folder <- function() {

  path_cache <- file.path(tempdir(), "yf_cache")

  return(path_cache)
}
