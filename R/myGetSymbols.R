#' An improved version of function \code{\link[quantmod]{getSymbols}} from quantmod
#'
#' This is a helper function to \code{\link{BatchGetSymbols}} and it should normaly not be called directly. The purpose of this function is to download financial data based on a ticker and a time period.
#' The main difference from \code{\link[quantmod]{getSymbols}} is that it imports the data as a dataframe with proper named columns and saves data locally with the caching system.
#'
#' @param ticker A single ticker to download data
#' @param src The source of the data ('google' or'yahoo')
#' @param i.ticker A index for the stock that is downloading (for cat() purposes)
#' @param length.tickers total number of stocks being downloaded (also for cat() purposes)
#' @param df.bench Data for bechmark ticker
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe with the financial data
#'
#' @export
#' @seealso \link[quantmod]{getSymbols} for the base function
#'
#' @examples
#' ticker <- 'FB'
#'
#' first.date <- Sys.Date()-30
#' last.date <- Sys.Date()
#'
#' \dontrun{
#' df.ticker <- myGetSymbols(ticker,
#'                           first.date = first.date,
#'                           last.date = last.date)
#' }
myGetSymbols <- function(ticker,
                         i.ticker,
                         length.tickers,
                         src = 'yahoo',
                         first.date,
                         last.date,
                         do.cache = TRUE,
                         cache.folder = file.path(tempdir(),'BGS_Cache'),
                         df.bench = NULL,
                         be.quiet = FALSE,
                         thresh.bad.data) {


  if (!be.quiet) {
    message(paste0('\n', ticker,
                   ' | ', src, ' (', i.ticker,'|',
                   length.tickers,')'), appendLF = FALSE )
  }



  # do cache
  if ( (do.cache)) {

    # check if data is in cache files
    my.cache.files <- list.files(cache.folder, full.names = TRUE)

    if (length(my.cache.files) > 0)  {
      l.out <- stringr::str_split(tools::file_path_sans_ext(basename(my.cache.files)),
                                  '_')

      df.cache.files <- dplyr::tibble(f.name = my.cache.files,
                                      ticker = sapply(l.out, function(x) x[1]),
                                      src =  sapply(l.out, function(x) x[2]),
                                      first.date =  as.Date(sapply(l.out, function(x) x[3])),
                                      last.date =  as.Date(sapply(l.out, function(x) x[4])))

    } else {
      # empty df
      df.cache.files <-  dplyr::tibble(f.name = '',
                                       ticker = '',
                                       src =  '',
                                       first.date =  first.date,
                                       last.date =  last.date)

    }

    # check dates
    fixed.ticker <-fix.ticker.name(ticker)

    temp.cache <- dplyr::filter(df.cache.files,
                                ticker == fixed.ticker,
                                src == src)

    if (nrow(temp.cache) > 1) {
      stop(paste0('Found more than one file in cache for ', ticker,
                  '\nYou must manually remove one of \n\n', paste0(temp.cache$f.name, collapse = '\n')))
    }

    if (nrow(temp.cache) != 0) {

      df.cache <- data.frame()
      flag.dates <- TRUE

      if (!be.quiet) {
        message(' | Found cache file', appendLF = FALSE )
      }

      df.cache <- readRDS(temp.cache$f.name)

      # check if data matches

      max.diff.dates <- 0
      flag.dates <- ((first.date -  temp.cache$first.date) < - max.diff.dates )|
        ((last.date -  temp.cache$last.date) > max.diff.dates)

      df.out <- data.frame()
      if (flag.dates) {

        if (!be.quiet) {
          message(' | Need new data', appendLF = FALSE )
        }

        flag.date.bef <- ((first.date -  temp.cache$first.date) < - max.diff.dates )
        df.out.bef <- data.frame()
        if (flag.date.bef) {
          df.out.bef <- get.clean.data(ticker,
                                       src,
                                       first.date,
                                       temp.cache$first.date)
        }

        flag.date.aft <- ((last.date -  temp.cache$last.date) > max.diff.dates)
        df.out.aft <- data.frame()
        if (flag.date.aft) {
          df.out.aft <- get.clean.data(ticker,
                                       src,
                                       temp.cache$last.date,
                                       last.date)
        }

        df.out <- rbind(df.out.bef, df.out.aft)
      }

      # merge with cache
      df.out <- unique(rbind(df.cache, df.out))

      # sort it
      if (nrow(df.out) > 0 ) {
        idx <- order(df.out$ticker, df.out$ref.date)
        df.out <- df.out[idx, ]
      }


      # remove old file
      file.remove(temp.cache$f.name)

      my.f.out <- paste0(fixed.ticker, '_',
                         src, '_',
                         min(c(temp.cache$first.date, first.date)), '_',
                         max(c(temp.cache$last.date, last.date)), '.rds')

      saveRDS(df.out, file = file.path(cache.folder, my.f.out))

      # filter for dates
      ref.date <- NULL
      df.out <- dplyr::filter(df.out,
                              ref.date >= first.date,
                              ref.date <= last.date)

    } else {
      if (!be.quiet) {
        message(' | Not Cached', appendLF = FALSE )
      }

      my.f.out <- paste0(fixed.ticker, '_',
                         src, '_',
                         first.date, '_',
                         last.date, '.rds')

      df.out <- get.clean.data(ticker,
                               src,
                               first.date,
                               last.date)

      # only saves if there is data
      if (nrow(df.out) > 1) {
        if (!be.quiet) {
          message(' | Saving cache', appendLF = FALSE )
        }
        saveRDS(df.out, file = file.path(cache.folder, my.f.out))
      }
    }

  } else {
    df.out <- get.clean.data(ticker,
                             src,
                             first.date,
                             last.date)
  }

  # control for ERROr in download
  if (nrow(df.out) == 0 ){
    download.status = 'NOT OK'
    total.obs = 0
    perc.benchmark.dates = 0
    threshold.decision = 'OUT'

    df.out <- data.frame()
    if (!be.quiet) {
      message(' - Error in download..', appendLF = FALSE )
    }
  } else {

    # control for returning data when importing bench ticker
    if (is.null(df.bench)) return(df.out)

    download.status = 'OK'
    total.obs = nrow(df.out)
    perc.benchmark.dates = sum(df.out$ref.date %in% df.bench$ref.date)/length(df.bench$ref.date)

    if (perc.benchmark.dates >= thresh.bad.data){
      threshold.decision = 'KEEP'
    } else {
      threshold.decision = 'OUT'
    }

    morale.boost <- c(rep(c('OK!', 'Got it!','Nice!','Good stuff!',
                            'Looking good!', 'Good job!', 'Well done!',
                            'Feels good!', 'You got it!', 'Youre doing good!'), 10),
                      'Boa!', 'Mas bah tche, que coisa linda!',
                      'Mais contente que cusco de cozinheira!',
                      'Feliz que nem lambari de sanga!',
                      'Mais faceiro que guri de bombacha nova!')

    if (!be.quiet) {
      if (threshold.decision == 'KEEP') {
        message(paste0(' - ', 'Got ', scales::percent(perc.benchmark.dates), ' of valid prices | ',
                       sample(morale.boost, 1)), appendLF = FALSE )
      } else {
        message(paste0(' - ', 'Got ', scales::percent(perc.benchmark.dates), ' of valid prices | ',
                       'OUT: not enough data (thresh.bad.data = ', scales::percent(thresh.bad.data), ')'),
                appendLF = FALSE )

      }
    }

    df.control <- tibble::tibble(ticker=ticker,
                                 src = src,
                                 download.status,
                                 total.obs,
                                 perc.benchmark.dates,
                                 threshold.decision)

    l.out <- list(df.tickers = df.out, df.control = df.control)

    return(l.out)


  }
}
