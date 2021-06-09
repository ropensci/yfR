#' An improved version of function quantmod::getSymbols
yf_get_single_ticker <- function(ticker,
                                 i_ticker,
                                 length_tickers,
                                 src = 'yahoo',
                                 first_date,
                                 last_date,
                                 do_cache = TRUE,
                                 cache_folder = yf_get_default_cache_folder(),
                                 df_bench = NULL,
                                 be_quiet = FALSE,
                                 thresh_bad_data) {


  if (!be_quiet) {
    message(paste0('\n', ticker,
                   ' | ', src, ' (', i_ticker,'|',
                   length_tickers,')'), appendLF = FALSE )
  }



  # do cache
  if ( (do_cache)) {

    # check if data is in cache files
    my_cache_files <- list.files(cache_folder, full.names = TRUE)

    if (length(my_cache_files) > 0)  {
      l_out <- stringr::str_split(tools::file_path_sans_ext(basename(my_cache_files)),
                                  '_')

      df_cache_files <- dplyr::tibble(filename = my_cache_files,
                                      ticker = sapply(l_out, function(x) x[1]),
                                      src =  sapply(l_out, function(x) x[2]),
                                      first_date =  as.Date(sapply(l_out, function(x) x[3])),
                                      last_date =  as.Date(sapply(l_out, function(x) x[4])))

    } else {
      # empty df
      df_cache_files <-  dplyr::tibble(filename = '',
                                       ticker = '',
                                       src =  '',
                                       first_date =  first_date,
                                       last_date =  last_date)

    }

    # check dates
    fixed_ticker <-fix.ticker.name(ticker)

    temp_cache <- dplyr::filter(df_cache_files,
                                ticker == fixed_ticker,
                                src == src)

    if (nrow(temp_cache) > 1) {
      stop(paste0('Found more than one file in cache for ', ticker,
                  '\nYou must manually remove one of \n\n', paste0(temp_cache$filename, collapse = '\n')))
    }

    if (nrow(temp_cache) != 0) {

      df_cache <- dplyr::tibble()
      flag_dates <- TRUE

      if (!be_quiet) {
        message(' | Found cache file', appendLF = FALSE )
      }

      df_cache <- readr::read_rds(temp_cache$filename)

      # check if data matches

      max_diff_dates <- 0
      flag_dates <- ((first_date -  temp_cache$first_date) < - max_diff_dates )|
        ((last_date -  temp_cache$last_date) > max_diff_dates)

      df_out <- data.frame()
      if (flag_dates) {

        if (!be_quiet) {
          message(' | Need new data', appendLF = FALSE )
        }

        flag_date_bef <- ((first_date -  temp_cache$first_date) < - max_diff_dates )
        df_out_bef <- data.frame()
        if (flag_date_bef) {
          df_out_bef <- get.clean.data(ticker,
                                       src,
                                       first_date,
                                       temp_cache$first_date)
        }

        flag_date_aft <- ((last_date -  temp_cache$last_date) > max_diff_dates)
        df_out_aft <- data.frame()
        if (flag_date_aft) {
          df_out_aft <- get.clean.data(ticker,
                                       src,
                                       temp_cache$last_date,
                                       last_date)
        }

        df_out <- rbind(df_out_bef, df_out_aft)
      }

      # merge with cache
      df_out <- unique(rbind(df_cache, df_out))

      # sort it
      if (nrow(df_out) > 0 ) {
        idx <- order(df_out$ticker, df_out$ref_date)
        df_out <- df_out[idx, ]
      }


      # remove old file
      file.remove(temp_cache$filename)

      my_f_out <- paste0(fixed_ticker, '_',
                         src, '_',
                         min(c(temp_cache$first_date, first_date)), '_',
                         max(c(temp_cache$last_date, last_date)), '.rds')

      readr::write_rds(df_out, file.path(cache_folder, my_f_out))

      # filter for dates
      ref_date <- NULL
      df_out <- dplyr::filter(df_out,
                              ref_date >= first_date,
                              ref_date <= last_date)

    } else {
      if (!be_quiet) {
        message(' | Not Cached', appendLF = FALSE )
      }

      my_f_out <- paste0(fixed_ticker, '_',
                         src, '_',
                         first_date, '_',
                         last_date, '.rds')

      df_out <- yf_get_clean_data(ticker,
                                  first_date,
                                  last_date)

      # only saves if there is data
      if (nrow(df_out) > 1) {
        if (!be_quiet) {
          message(' | Saving cache', appendLF = FALSE )
        }
        readr::write_rds(df_out, file = file.path(cache_folder, my_f_out))
      }
    }

  } else {
    df_out <- get_clean_data(ticker,
                             first_date,
                             last_date)
  }

  # control for ERROr in download
  if (nrow(df_out) == 0 ){
    dl_status = 'NOT OK'
    n_rows = 0
    perc_benchmark_dates = 0
    threshold_decision = 'OUT'

    df_out <- data.frame()
    if (!be_quiet) {
      message(' - Error in download..', appendLF = FALSE )
    }
  } else {

    # control for returning data when importing bench ticker
    if (is.null(df_bench)) return(df_out)

    dl_status = 'OK'
    n_rows = nrow(df_out)
    perc_benchmark_dates = sum(df_out$ref_date %in% df_bench$ref_date)/length(df_bench$ref_date)

    if (perc_benchmark_dates >= thresh_bad_data){
      threshold_decision = 'KEEP'
    } else {
      threshold_decision = 'OUT'
    }

    # a morale boost phrase
    morale_boost <- get_morale_boost()

    if (!be_quiet) {
      if (threshold_decision == 'KEEP') {
        message(paste0(' - ', 'Got ', scales::percent(perc_benchmark_dates), ' of valid prices | ',
                       morale_boost), appendLF = FALSE )
      } else {
        message(paste0(' - ', 'Got ', scales::percent(perc_benchmark_dates), ' of valid prices | ',
                       'OUT: not enough data (thresh_bad_data = ', scales::percent(thresh_bad_data), ')'),
                appendLF = FALSE )

      }
    }

    df.control <- tibble::tibble(ticker=ticker,
                                 src = src,
                                 dl_status,
                                 n_rows,
                                 perc_benchmark_dates,
                                 threshold_decision)

    l_out <- list(df.tickers = df_out, df.control = df.control)

    return(l_out)


  }
}
