#' Returns the default folder for caching
#'
#' By default, yfR uses a temp dir to store files.
#'
#' @return a path (string)
#' @export
#'
#' @examples
#' print(yf_cachefolder_get())
yf_cachefolder_get <- function() {

  path_cache <- file.path(tempdir(), "yf_cache")

  return(path_cache)
}
