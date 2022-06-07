#' function to import a single ticker
#' @noRd
yf_data_single <- function(ticker,
                                 i_ticker,
                                 length_tickers,
                                 first_date,
                                 last_date,
                                 do_cache = TRUE,
                                 cache_folder = yf_cachefolder_get(),
                                 df_bench = NULL,
                                 be_quiet = FALSE,
                                 thresh_bad_data) {
  if (!be_quiet) {
    my_msg <- set_cli_msg("({i_ticker}/{length_tickers}) Fetching data for {ticker}")
    cli::cli_alert_info(my_msg)
  }

  # do cache
  if (do_cache) {

    # check if data is in cache files
    my_cache_files <- list.files(cache_folder, full.names = TRUE)

    if (length(my_cache_files) > 0) {
      l_out <- stringr::str_split(
        tools::file_path_sans_ext(basename(my_cache_files)),
        "_"
      )

      df_cache_files <- dplyr::tibble(
        filename = my_cache_files,
        ticker = purrr::map_chr(l_out, function(x) x[1]),
        first_date = as.Date(purrr::map_chr(l_out, function(x) x[3])),
        last_date = as.Date(purrr::map_chr(l_out, function(x) x[4]))
      )
    } else {
      # empty df
      df_cache_files <- dplyr::tibble(
        filename = "",
        ticker = "",
        first_date = first_date,
        last_date = last_date
      )
    }

    # check dates
    fixed_ticker <- fix_ticker_name(ticker)

    temp_cache <- dplyr::filter(
      df_cache_files,
      ticker == fixed_ticker
    )

    if (nrow(temp_cache) > 1) {
      my_msg <- paste0(
        "Found more than one file in cache for ", ticker,
        "\nYou must manually remove one of \n\n",
        paste0(temp_cache$filename,
               collapse = "\n")
      )
      stop(my_msg)

      stop()
    }

    if (nrow(temp_cache) != 0) {
      flag_dates <- TRUE
      df_cache <- readr::read_rds(temp_cache$filename)

      if (!be_quiet) {
        this_fd <- as.character(min(df_cache$ref_date))
        this_ld <- as.character(max(df_cache$ref_date))

        my_msg <- set_cli_msg("found cache file ({this_fd} --> {this_ld})",
          level = 1
        )
        cli::cli_alert_success(my_msg)
      }

      # check if data matches

      max_diff_dates <- 0
      flag_dates <- ((first_date - temp_cache$first_date) < -max_diff_dates) |
        ((last_date - temp_cache$last_date) > max_diff_dates)

      df_out <- data.frame()
      if (flag_dates) {
        if (!be_quiet) {
          my_msg <- set_cli_msg("need new data (cache doesnt match query)",
            level = 1
          )

          cli::cli_alert_warning(my_msg)
        }

        flag_date_bef <- ((first_date - temp_cache$first_date) <
                            -max_diff_dates)
        df_out_bef <- data.frame()
        if (flag_date_bef) {
          df_out_bef <- yf_data_get_raw(
            ticker,
            first_date,
            temp_cache$first_date
          )
        }

        flag_date_aft <- ((last_date - temp_cache$last_date) > max_diff_dates)
        df_out_aft <- data.frame()
        if (flag_date_aft) {
          df_out_aft <- yf_data_get_raw(
            ticker,
            temp_cache$last_date,
            last_date
          )
        }

        df_out <- rbind(df_out_bef, df_out_aft)
      }

      # merge with cache
      df_out <- unique(rbind(df_cache, df_out))

      # sort it
      if (nrow(df_out) > 0) {
        idx <- order(df_out$ticker, df_out$ref_date)
        df_out <- df_out[idx, ]
      }


      # remove old file
      file.remove(temp_cache$filename)

      my_f_out <- paste0(
        fixed_ticker, "_",
        "yfR_",
        min(c(temp_cache$first_date, first_date)), "_",
        max(c(temp_cache$last_date, last_date)), ".rds"
      )

      readr::write_rds(df_out, file.path(cache_folder, my_f_out))

      # filter for dates
      ref_date <- NULL
      df_out <- dplyr::filter(
        df_out,
        ref_date >= first_date,
        ref_date <= last_date
      )
    } else {
      if (!be_quiet) {
        my_msg <- set_cli_msg("not cached",
          level = 1
        )

        cli::cli_alert_warning(my_msg)
      }

      my_f_out <- paste0(
        fixed_ticker, "_",
        "yfR_",
        first_date, "_",
        last_date, ".rds"
      )

      df_out <- yf_data_get_raw(
        ticker,
        first_date,
        last_date
      )

      # only saves if there is data
      if (nrow(df_out) > 1) {
        if (!be_quiet) {
          my_msg <- set_cli_msg("cache saved successfully",
            level = 1
          )
          cli::cli_alert_success(my_msg)
        }
        readr::write_rds(df_out, file = file.path(cache_folder, my_f_out))
      }
    }
  } else {
    df_out <- yf_data_get_raw(
      ticker,
      first_date,
      last_date
    )
  }

  # control for ERROR in download
  if (nrow(df_out) == 0) {
    dl_status <- "NOT OK"
    n_rows <- 0
    perc_benchmark_dates <- 0
    threshold_decision <- "OUT"

    df_out <- data.frame()
    if (!be_quiet) {
      my_msg <- set_cli_msg("error in download..",
        level = 1
      )
      cli::cli_alert_danger(my_msg)
    }
  } else {

    # control for returning data when importing bench ticker
    if (is.null(df_bench)) {
      return(df_out)
    }

    dl_status <- "OK"
    n_rows <- nrow(df_out)
    perc_benchmark_dates <- sum(df_out$ref_date %in% df_bench$ref_date) /
      length(df_bench$ref_date)

    if (perc_benchmark_dates >= thresh_bad_data) {
      threshold_decision <- "KEEP"
    } else {
      threshold_decision <- "OUT"
    }

    # a morale boost phrase
    morale_boost <- get_morale_boost()

    if (!be_quiet) {
      if (threshold_decision == "KEEP") {
        this_fd <- as.character(min(df_out$ref_date))
        this_ld <- as.character(max(df_out$ref_date))

        my_msg <- set_cli_msg(
          "got {nrow(df_out)} valid rows ({this_fd} --> {this_ld})",
          level = 1
        )

        cli::cli_alert_success(my_msg)

        my_msg <- set_cli_msg(paste0(
          "got {scales::percent(perc_benchmark_dates)} ",
          "of valid prices -- {morale_boost}"
        ),
        level = 1
        )

        cli::cli_alert_success(my_msg)
      } else {
        my_msg <- set_cli_msg(paste0(
          "**REMOVED** found only {scales::percent(perc_benchmark_dates)} of ",
          "valid prices (thresh_bad_data = {scales::percent(thresh_bad_data)})"
        ),
        level = 1
        )

        cli::cli_alert_danger(my_msg)
      }
    }

    df_control <- tibble::tibble(
        ticker = ticker,
        dl_status,
        n_rows,
        perc_benchmark_dates,
        threshold_decision
      )

    l_out <- list(df_tickers = df_out,
                  df_control = df_control)

    return(l_out)
  }
}
