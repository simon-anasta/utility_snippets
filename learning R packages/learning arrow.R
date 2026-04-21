# Understanding arrow package
# 2026-04-21
#
# References:
# https://arrow.apache.org/docs/r/
# https://www.r-bloggers.com/2022/11/handling-larger-than-memory-data-with-arrow-and-duckdb/
# https://arrow.apache.org/docs/r/
# 
# https://r4ds.hadley.nz/arrow
# https://arrowrbook.com/foreword.html
# https://arrow.apache.org/cookbook/r/index.html
# 
# Arrow can be used for streaming files from disc.
# Especially designed for large or distributed files (parquet / feather)
# but also applicable to plain csv files.
# 

## setup ----

install.packages("arrow", "DBI")
library(arrow)

## create large file to disk ----

size = 10000
iterations = 1000

for(ii in seq_len(iterations)){
  
  tmp = data.frame(
    id = sample(1:1000, size, replace = TRUE),
    class = sample(c("a","b","c","d","e","f","g","h"), size, replace = TRUE),
    real = runif(size),
    stringsAsFactors = FALSE
  )
  
  ii_is_1 = ifelse(ii == 1, TRUE, FALSE)
  write.table(tmp, "test.csv", sep = ",", row.names = FALSE, col.names = ii_is_1, append = !ii_is_1)
}

# tidy
rm(list = ls())

## access file for streaming ----

df = open_dataset("./test.csv", format = "csv")
object.size(df) |>
  print(units = "KiB")
# 0.5 KiB

## common tasks ----
# all with dplyr translation under the hood

df |>
  colnames()

df |>
  head(10) |>
  dplyr::collect()

qq = df |>
  dplyr::filter(id <= 20) |>
  dplyr::group_by(class) |>
  dplyr::summarise(
    total = sum(real),
    num = dplyr::n()
  )

class(qq)
dplyr::show_query(qq) # not a readable to me as SQL
print(qq) # not informative until collected
print(dplyr::collect(qq)) # must collect to see results

nrow(df) # available direct, unlike with a database

## performance comparison against duckdb - including setup times ----

direct_use_of_arrow = function(){
  open_dataset("./test.csv", format = "csv") |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

duckdb_without_arrow = function(){
  con = DBI::dbConnect(duckdb::duckdb())
  duckdb::duckdb_read_csv(con, "test", "test.csv")
  dplyr::tbl(con, "test") |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
  DBI::dbDisconnect(con)
}

arrow_to_duckdb = function(){
  open_dataset("./test.csv", format = "csv") |>
    to_duckdb() |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

microbenchmark::microbenchmark(
  # direct use of arrow
  direct_use_of_arrow(),
  # duckdb without arrow
  duckdb_without_arrow(),
  # explicit use of both together
  arrow_to_duckdb(),
  times = 10
)

# Unit: milliseconds   
                  # expr      min       lq      mean   median       uq      max neval
# direct_use_of_arrow()   45.2709  46.2544  49.28163  47.1999  52.5492  59.2337    10
# duckdb_without_arrow() 687.6267 689.2069 732.18946 739.5909 755.9674 787.0593    10
# arrow_to_duckdb()       76.3501  83.2064  95.99286  90.0925  93.8945 167.3729    10

# for this application
# 
# direct use of arrow was fastest
# arrow to duckdb was slower by about 2x
# duckdb without arrow was slower by about 10x
#
# though all operations concluded in under a second

## performance comparison against duckdb - excluding setup times ----

arrow_file = open_dataset("./test.csv", format = "csv")
arrow_duck = open_dataset("./test.csv", format = "csv") |>
  to_duckdb()

con = DBI::dbConnect(duckdb::duckdb())
duckdb::duckdb_read_csv(con, "test", "test.csv")
duckdb_file = dplyr::tbl(con, "test")

direct_use_of_arrow = function(){
  arrow_file |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

duckdb_without_arrow = function(){
  duckdb_file |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

arrow_to_duckdb = function(){
   arrow_duck |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

arrow_to_duckdb2 = function(){
  arrow_file |>
    to_duckdb() |>
    dplyr::filter(id <= 20) |>
    dplyr::group_by(class) |>
    dplyr::summarise(
      total = sum(real),
      num = dplyr::n()
    )
}

microbenchmark::microbenchmark(
  # direct use of arrow
  direct_use_of_arrow(),
  # duckdb without arrow
  duckdb_without_arrow(),
  # explicit use of both together
  arrow_to_duckdb(),
  arrow_to_duckdb2(),
  times = 10
)

DBI::dbDisconnect(con)

# Unit: milliseconds   
#                   expr     min      lq     mean   median      uq      max neval
# direct_use_of_arrow()  29.2276 29.5464 38.73891 30.45305 33.2136 109.5100    10
# duckdb_without_arrow() 51.2600 53.6633 58.95133 56.91200 65.0589  73.2782    10
# arrow_to_duckdb()      49.4088 51.3520 55.86185 53.73335 59.4344  66.3575    10
# arrow_to_duckdb2()     62.3298 69.2233 79.31569 71.70355 75.1917 149.7241    10

# for this application
# 
# minimal difference between the different approaches.
# suggesting that the differences in the previous benchmark are mostly due to
# setup times, not computation times.
#
# direct use of arrow still appears the fastest. But by a factor closer to 1.5x
# 
