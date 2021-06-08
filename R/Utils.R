#' Fix name of ticker
#'
#' Removes bad symbols from names of tickers. This is useful for naming files with cache system.
#'
#' @param ticker.in A bad ticker name
#' @return A good ticker name
#'
fix.ticker.name <- function(ticker.in){

  ticker.in <- stringr::str_replace_all(ticker.in, stringr::fixed('.'), '')
  ticker.in <- stringr::str_replace_all(ticker.in, stringr::fixed('^'), '')

  return(ticker.in)
}


#' Get clean data from yahoo/google
#'
#' @param src Source of data (yahoo or google)
#' @inheritParams BatchGetSymbols
#'
#' @return A dataframe with the cleaned data
#'
get.clean.data <- function(tickers,
                           src = 'yahoo',
                           first.date,
                           last.date) {

  # dont push luck with yahoo servers
  # No problem in my testings, so far. You can safely leave it unrestricted
  #Sys.sleep(0.5)

  # set empty df for errors
  df.out <- data.frame()

  suppressMessages({
    suppressWarnings({
      try(df.out <- quantmod::getSymbols(Symbols = tickers,
                                          src = src,
                                          from = first.date,
                                          to = last.date,
                                          auto.assign = F),
          silent = T)
    }) })

  if (nrow(df.out) == 0) return(df.out)

  df.out <- as.data.frame(df.out[!duplicated(zoo::index(df.out))])

  # adjust df for difference of columns from yahoo and google
  if (src=='google'){

    colnames(df.out) <- c('price.open','price.high','price.low','price.close','volume')
    df.out$price.adjusted <- NA

  } else {

    colnames(df.out) <- c('price.open','price.high','price.low','price.close','volume','price.adjusted')
  }

  # get a nice column for dates and tickers
  df.out$ref.date <- as.Date(rownames(df.out))
  df.out$ticker <- tickers

  # remove rownames
  rownames(df.out) <- NULL

  # remove rows with NA
  idx <- !is.na(df.out$price.adjusted)
  df.out <- df.out[idx, ]

  if (nrow(df.out) ==0) return('Error in download')

  return(df.out)
}


#' Transforms a dataframe in the long format to a list of dataframes in the wide format
#'
#' @param df.tickers Dataframe in the long format
#'
#' @return A list with dataframes in the wide format
#'
reshape.wide <- function(df.tickers) {

  cols.to.keep <- c('ref.date', 'ticker')

  my.cols <- setdiff(names(df.tickers), cols.to.keep)

  fct.format.wide <- function(name.in, df.tickers) {

    temp.df <- df.tickers[, c('ref.date', 'ticker', name.in)]

    ticker <- NULL # fix for CHECK: "no visible binding..."
    temp.df.wide <- tidyr::spread(temp.df, ticker, name.in)
    return(temp.df.wide)

  }

  l.out <- lapply(my.cols, fct.format.wide, df.tickers = df.tickers)
  names(l.out) <- my.cols

  return(l.out)

}


#' Function to calculate returns from a price and ticker vector
#'
#' Created so that a return column is added to a dataframe with prices in the long (tidy) format.
#'
#' @param P Price vector
#' @param tickers Ticker of symbols (usefull if working with long dataframe)
#' @inheritParams BatchGetSymbols
#'
#' @return A vector of returns
#' @export
#'
#' @examples
#' P <- c(1,2,3)
#' R <- calc.ret(P)
calc.ret <- function(P,
                     tickers = rep('ticker', length(P)),
                     type.return = 'arit') {

  my.length <- length(P)

  ret <- switch(type.return,
                'arit' = P/dplyr::lag(P) - 1,
                'log' = log(P/dplyr::lag(P)) )

  idx <- (tickers != dplyr::lag(tickers))
  ret[idx] <- NA

  return(ret)
}

#' Replaces NA values in dataframe for closest price
#'
#' Helper function for BatchGetSymbols. Replaces NA values and returns fixed dataframe.
#'
#' @param df.in DAtaframe to be fixed
#'
#' @return A fixed dataframe.
df.fill.na = function(df.in) {


  # find NAs or volume == 0
  idx.na <- which(is.na(df.in$price.adjusted) |
                    df.in$volume == 0)

  if (length(idx.na) ==0) return(df.in)

  idx.not.na <- which(!is.na(df.in$price.adjusted))

  cols.to.adjust <- c("price.open", "price.high", "price.low",
                      "price.close", "price.adjusted")

  print(unique(df.in$ticker))

  cols.to.adjust <- cols.to.adjust[cols.to.adjust %in% names(df.in)]

  # function for finding closest price
  fct.find.min.dist <- function(x, vec.comp) {

    if (x < min(vec.comp)) return(min(vec.comp))

    my.dist <- x - vec.comp
    my.dist <- my.dist[my.dist > 0]
    idx <- which.min(my.dist)[1]

    return(vec.comp[idx])

  }

  for (i.col in cols.to.adjust) {

    # adjust for NA by replacing values
    idx.to.use <- sapply(idx.na,
                         fct.find.min.dist,
                         vec.comp = idx.not.na)

    df.in[idx.na, i.col] <- unlist(df.in[idx.to.use, i.col])

  }

  # adjust volume for all NAs
  df.in$volume[idx.na] <- 0

  return(df.in)

}


.onAttach <- function(libname,pkgname) {

  do_color <- crayon::make_style("#FF4141")
  this_pkg <- 'BatchGetSymbols'

  if (interactive()) {
    msg <- paste0('\nWant to learn more about ',
                  do_color(this_pkg), ' and other R packages for Finance and Economics?',
                  '\nThe second edition (2020) of ',
                  do_color('Analyzing Financial and Economic Data with R'), ' is available at\n',
                  do_color('https://www.msperlin.com/afedR/') )
  } else {
    msg <- ''
  }

  packageStartupMessage(msg)

}

