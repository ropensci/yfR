#' Fix name of ticker
#' @noRd
fix_ticker_name <- function(ticker_in) {
  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed("."), "")
  ticker_in <- stringr::str_replace_all(ticker_in, stringr::fixed("^"), "")

  return(ticker_in)
}

#' returns a morale phrase (used in cli messages)
#' @noRd
get_morale_boost <- function() {

  my_user <- Sys.getenv("USER")

  morale_boost <- c(
    rep(c(
      "All OK!",
      "Time for some tea?",
      "Got it!", "Nice!", "Good stuff!",
      "Looking good!", "Good job {my_user}!",
      "Well done {my_user}!",
      "You got it {my_user}!", "Youre doing good!"
    ), 10),
    "Boa!", "Mas bah tche, que coisa linda!",
    "Parabens {my_user}, tudo certo!",
    "Mais contente que cusco de cozinheira!",
    "Feliz que nem lambari de sanga!",
    "Mais faceiro que guri de bombacha nova!"
  )

  return(stringr::str_glue(sample(morale_boost, 1)))
}

#' Converts string date to unix date (used in yf query)
#' @noRd
date_to_unix <- function(date_in) {
  out <- as.numeric(
    as.POSIXct(as.Date(date_in,
                       origin = "1970-01-01"
    ))
  )
  return(out)
}

#' Converses unix date to string date
#' @noRd
unix_to_date <- function(unix_date_in) {

  out <- as.Date(as.POSIXct(unix_date_in, origin="1970-01-01"))

  return(out)
}

#' Function to calculate returns from a price and ticker vector
#' @noRd
calc_ret <- function(P,
                     tickers = rep("ticker", length(P)),
                     type_return = "arit") {
  my_length <- length(P)

  if (my_length == 1) {
    return(NA)
  }

  ret <- switch(type_return,
                "arit" = P / dplyr::lag(P) - 1,
                "log" = log(P / dplyr::lag(P))
  )

  idx <- (tickers != dplyr::lag(tickers))
  ret[idx] <- NA

  return(ret)
}

#' Function to calculate accumulated returns from a price and ticker vector
#' @noRd
calc_cum_ret <- function(ret,
                         tickers = rep("ticker", length(ret)),
                         type_return = "arit") {

  # replace all NAs by 0
  idx <- is.na(ret)
  ret[idx] <- 0

  l_ret <- split(ret, tickers)

  calc_cum <- function(x, type_return) {
    this_cum_ret <- switch(type_return,
                           "arit" = cumprod(1 + x),
                           "log" = 1 + cumsum(x))

    return(this_cum_ret)
  }

  l_cum_ret <- purrr::map(l_ret,
                          calc_cum,
                          type_return = type_return)

  cum_ret <- do.call(c, l_cum_ret)

  names(cum_ret) <- NULL

  return(cum_ret)
}


# 20220328 - removed startup message due to ropensci practices
# https://devguide.ropensci.org/building.html

# .onAttach <- function(libname, pkgname) {
#   do_color <- crayon::make_style("#FF4141")
#   this_pkg <- "yfR"
#
#   if (interactive()) {
#     msg <- paste0(
#       "\nWant to learn more about ",
#       do_color(this_pkg), " (formerly BatchGetSymbols) and other R packages",
#       "for Finance and Economics?",
#       " Check out my book at ", do_color("https://www.msperlin.com/afedR/")
#     )
#   } else {
#     msg <- ""
#   }
#
#   packageStartupMessage(msg)
# }

#' Function for building cli messages
#' @noRd
set_cli_msg <- function(msg_in, level = 0) {
  tab_in <- paste0(rep("\t", level), collapse = "")

  if (level == 1) {
    tab_in <- paste0(tab_in, "- ")
  }

  msg_in <- paste0(tab_in, msg_in)
  return(msg_in)
}

#' Fixes ticker manually
#'
#' This function will be used as a dictionary to fix wrong tickers from index compositions
#'
#' @param df_index
#'
#' @return Another dataframe
#'
#' @noRd
substitute_tickers <- function(df_index) {

  df_fix <- dplyr::tibble(
    old = c("BF.B"),
    new = c("BF-B")
  )

  idx <- match(df_fix$old, df_index$ticker)

  df_index$ticker[idx] <- df_fix$new

  return(df_index)
}


#' Tests for an internet connection
#'
#' Tests for internet connect in every R session. If already tested, just skip it and saves time.
#'
#' @noRd
check_internet <- function() {
  f_flag <- paste0(
    tempdir(), "/",
    "yf-flag-internet-ok"
  )

  if (file.exists(f_flag)) {

    flag <- TRUE

  } else {

    flag <- pingr::is_online()

    if (!flag) {
      stop("Can't find an active internet connection...")
    } else {
      readr::write_lines("internet ok", f_flag)
    }

  }

  return(flag)
}


#' Convert bytes to a more natural representation
#'
#' Copied from https://github.com/gerrymanoim/humanize/blob/master/R/filesize.R
#'
#' @noRd
natural_size <- function(bytes, suffix_type="decimal", fmt='%.1f') {

  suffixes <- list(
    'decimal' =  c('kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'),
    'binary' = c('KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'),
    'gnu' = c("K","M","G","T","P","E","Z","Y")
  )

  stopifnot(suffix_type %in% names(suffixes))
  # How much value check do I need for bytes?
  suffix <- suffixes[[suffix_type]]
  gnu <- suffix_type == "gnu"

  base <- ifelse(suffix_type %in% c('gnu', 'binary'), 1024, 1000)

  if (bytes == 1 & !gnu) {
    return("1 Byte")
  } else if (bytes < base & !gnu) {
    return(glue::glue("{bytes} Bytes"))
  } else if (bytes < base & gnu) {
    return(glue::glue("{bytes}B"))
  }

  for (i in seq_along(suffix)) {
    unit <- base ^ (i + 1)
    if (bytes < unit) {
      out_val <- sprintf(fmt,(base * bytes / unit))
      if (gnu) {
        return(glue::glue("{out_val}{suffix[[i]]}"))
      } else {
        return(glue::glue("{out_val} {suffix[[i]]}"))
      }
    }
  }

  out_val <- sprintf(fmt,(base * bytes / unit))
  if (gnu) {
    return(glue::glue("{out_val}{suffix[[length(suffix)]]}"))
  }
  return(glue::glue("{out_val} {suffix[[length(suffix)]]}"))
}
