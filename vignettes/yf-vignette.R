## ---- echo=FALSE--------------------------------------------------------------

knitr::opts_chunk$set(eval=FALSE)


## ----example1, eval=TRUE, results='hide'--------------------------------------
if (!require(yfR)) install.packages('yfR')

library(yfR)

# set dates
first_date <- Sys.Date() - 60
last_date <- Sys.Date()
freq_data <- 'daily'
# set tickers
tickers <- c('FB','MMM','PETR4.SA')

df_yf <- yf_get_data(tickers = tickers, 
                         first_date = first_date,
                         last_date = last_date, 
                         freq_data = freq_data) # cache in tempdir()


## ----example2-----------------------------------------------------------------
#  str(df_yf)

## ----plot.prices, fig.width=7, fig.height=2.5---------------------------------
#  library(ggplot2)
#  
#  p <- ggplot(df_yf, aes(x = ref_date, y = price_close)) +
#    geom_line() + facet_wrap(~ticker, scales = 'free_y')
#  
#  print(p)

## ----example3,eval=FALSE------------------------------------------------------
#  library(yfR)
#  
#  first_date <- Sys.Date()-365
#  last_date <- Sys.Date()
#  
#  df_sp500 <- yf_get_collection('SP500')
#  

