library(testthat)
library(yf)

#test_that(desc = 'Test of download function',{
#          expect_equal(1, 1) } )

first.date <- Sys.Date()-30
last.date <- Sys.Date()

# my.tickers <- c('MMM')
# 
# l.out <- BatchGetSymbols(tickers = my.tickers,
#                          first.date = first.date,
#                          last.date = last.date)
# 
# 
# test_that(desc = 'Test of read function',{
#   expect_true(nrow(l.out$df.tickers)>0)
#   } )

#cat('\nDeleting test folder')
#unlink(dl.folder, recursive = T)

