## Version 0.0.4 (2022-05-22)

- new call to quantmod::GetSymbols() using json entry point, which, so far, 
is unrestricted. This fixes [issue 9](https://github.com/msperlin/yfR/issues/9).
- re-inserted the parallel option in yf_get (passed all tests)
- now using a function for testing collection download

- Added cumulative return at output

## Version 0.0.3 (2022-05-03)

- Added cumulative return at output

## Version 0.0.2 (2022-05-02)

- Added warning message for parallel option (yahoo finance has just set a api limit)
- Fixed typos in readme.md

## Version 0.0.1 (2022-03-28)

- First version, ported from [BatchGetSymbols](https://github.com/msperlin/BatchGetSymbols)
