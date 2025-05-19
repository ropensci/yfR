# global file set up for removing CRAN check messages
# "no visible binding for global variable"
# source: https://community.rstudio.com/t/how-to-solve-no-visible-binding-
#         for-global-variable-note/28887
my_globals <- c(
  "Date", "Open", "High", "Low", "Close",
  "Adj Close", "Volume", "ref_date",
  "price_open", "price_high", "price_low",
  "price_close", "price_adjusted", "volume",
  "EPIC", "Company", "Symbol", "Security",
  "GICS Sector", "ticker", "company", "sector",
  "time_groups", "first", "last",
  "Ticker", "Industry", "Headquarters",
  # from yf_live_prices
  "meta", "symbol", "regularMarketTime", "regularMarketPrice",
  "time_stamp","previousClose","price","last_price",
  # from yf_live_prices
  "amount",
  "acao", "codigo", "index", "index_ticker", "tipo", "type_stock"
)

utils::globalVariables(my_globals)
