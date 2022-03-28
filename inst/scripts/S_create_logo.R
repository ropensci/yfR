library(hexSticker)
library(yfR)

df_sp500 <- yfR::yf_get_data('^GSPC', first_date = '1950-01-01') |>
  dplyr::ungroup() |>
  dplyr::select(ref_date, price_adjusted)


s <- sticker(~plot(df_sp500, cex=.5, cex.axis=.5, mgp=c(0,.3,0),
                   xlab="", ylab="SP500"),
             package="yfR",
             p_size=11,
             s_x=1,
             s_y=.8,
             s_width=1.4,
             s_height=1.2,
             filename="inst/figures/yfr_logo.png")
