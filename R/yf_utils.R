# Fix name of ticker
fix_ticker_name <- function(ticker_in){

  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed('.'), '')
  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed('^'), '')

  return(ticker_in)
}

# a morale phrase
get_morale_boost <- function() {
  my_user <- Sys.getenv('USER')
  morale_boost <- c(rep(c('All OK!',
                          'Time for some tea?',
                          'Got it!','Nice!','Good stuff!',
                          'Looking good!', 'Good job {my_user}!',
                          'Well done {my_user}!',
                          'You got it {my_user}!', 'Youre doing good!'), 10),
                    'Boa!', 'Mas bah tche, que coisa linda!',
                    'Parabens {my_user}, tudo certo!',
                    'Mais contente que cusco de cozinheira!',
                    'Feliz que nem lambari de sanga!',
                    'Mais faceiro que guri de bombacha nova!')

  return(stringr::str_glue(sample(morale_boost, 1)))
}

# converts date to unix (to yf query)
date_to_unix <- function(date_in) {
  out <- as.numeric(
    as.POSIXct(as.Date(date_in,
                       origin = "1970-01-01"))
  )
  return(out)
}


# Transforms a dataframe in the long format to a list of dataframes in the wide format
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


# Function to calculate returns from a price and ticker vector
calc_ret <- function(P,
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

# Replaces NA values in dataframe for closest price
df_fill_na = function(df_in) {


  # find NAs or volume == 0
  idx_na <- which(is.na(df_in$price.adjusted) |
                    df_in$volume == 0)

  if (length(idx_na) ==0) return(df_in)

  idx_not_na <- which(!is.na(df_in$price_adjusted))

  cols_to_adjust <- c("price_open", "price_high", "price_low",
                      "price_close", "price_adjusted")

  print(unique(df_in$ticker))

  cols_to_adjust <- cols_to_adjust[cols_to_adjust %in% names(df_in)]

  # function for finding closest price
  fct_find_min_dist <- function(x, vec.comp) {

    if (x < min(vec.comp)) return(min(vec.comp))

    my.dist <- x - vec.comp
    my.dist <- my.dist[my.dist > 0]
    idx <- which.min(my.dist)[1]

    return(vec.comp[idx])

  }

  for (i_col in cols_to_adjust) {

    # adjust for NA by replacing values
    idx_to_use <- sapply(idx_na,
                         fct_find_min_dist,
                         vec.comp = idx_not_na)

    df_in[idx_na, i_col] <- unlist(df_in[idx_to_use, i_col])

  }

  # adjust volume for all NAs
  df_in$volume[idx_na] <- 0

  return(df_in)

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

set_cli_msg <- function(msg_in, level = 0) {

  tab_in <- paste0(rep('\t', level), collapse = '')

  if (level == 1) {
    tab_in <- paste0(tab_in, '- ')
  }

  msg_in <- paste0(tab_in, msg_in)
  return(msg_in)

}
