# global file just fo removing CRAN check messages
# "no visible binding for global variable"
# source: https://community.rstudio.com/t/how-to-solve-no-visible-binding-for-global-variable-note/28887
my_globals <- c(
  'Date', 'Open', 'High', 'Low', 'Close',
  'Adj Close', 'Volume', 'ref_date',
  'price_open', 'price_high', 'price_low',
  'price_close', 'price_adjusted', 'volume',
  'EPIC', 'Company', 'Symbol', 'Security',
  'GICS Sector', 'ticker', 'company', 'sector',
  'time_groups', ''
)
utils::globalVariables(my_globals)
