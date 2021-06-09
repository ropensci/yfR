#' Fix name of ticker
fix_ticker_name <- function(ticker_in){

  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed('.'), '')
  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed('^'), '')

  return(ticker_in)
}

get_morale_boost <- function() {
  morale_boost <- c(rep(c('OK!', 'Got it!','Nice!','Good stuff!',
                          'Looking good!', 'Good job!', 'Well done!',
                          'Feels good!', 'You got it!', 'Youre doing good!'), 10),
                    'Boa!', 'Mas bah tche, que coisa linda!',
                    'Mais contente que cusco de cozinheira!',
                    'Feliz que nem lambari de sanga!',
                    'Mais faceiro que guri de bombacha nova!')

  return(sample(morale_boost, 1))
}

date_to_unix <- function(date_in) {
  out <- as.numeric(
    as.POSIXct(as.Date(date_in,
                       origin = "1970-01-01"))
  )
  return(out)
}


#' Transforms a dataframe in the long format to a list of dataframes in the wide format
reshape_wide <- function(df_in) {

  cols_to_keep <- c('ref_date', 'ticker')

  my_cols <- setdiff(names(df_in), cols_to_keep)

  fct_format_wide <- function(name_in, df_in) {

    temp_df <- df_in[, c('ref_date', 'ticker', name_in)]

    ticker <- NULL # fix for CHECK: "no visible binding..."
    temp_df_wide <- tidyr::spread(temp_df, ticker, name_in)
    return(temp_df_wide)

  }

  l_out <- lapply(my_cols, fct_format_wide, df_in = df_in)
  names(l_out) <- my_cols

  return(l_out)

}


#' Function to calculate returns from a price and ticker vector
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

