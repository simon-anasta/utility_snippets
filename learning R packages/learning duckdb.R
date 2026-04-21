# Understanding duckdb package for processing large files on disk
# 2026-04-21
#
# References:
# https://duckdb.org/docs/current/clients/r
# https://www.r-bloggers.com/2022/04/duckdb-quacking-sql/
# 
# duckdb is an 'embedded analytical database'.
# embedded >> part of current programme, not a separate server, shares memory
#   and CPU,minimal setup or admin. But, not designed for multiple users.
# analytical >> some databases are designed for transactional loads (small reads
#   & writes, frequent updates, high concurrency). duckdb is designed for
#   analytics (large table scans, complex adhoc SQL).
# 
# Our main interest in it is to stream files from disk rather than load files
# into memory. duckdb uses Arrow implicitly under the hood, but can be further
# accelerated by its explicit use.
# 

## setup ----

install.packages("duckdb", "DBI")
library(duckdb)

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

## test load direct as csv ----

df = read.csv("test.csv")
object.size(df) |>
  print(units = "MiB")
# 190.7 MiB

# tidy
rm(list = ls())

## access file from duckdb ----

con = DBI::dbConnect(duckdb::duckdb())
# remote_df = dplyr::tbl(con, "test.csv") # fails despite being in the documentation

# tell duckdb to stream csv file as a table names 'test'
duckdb::duckdb_read_csv(con, "test", "test.csv")
# create a remote database connection
remote_df = dplyr::tbl(con, "test")

size = sapply(ls(), function(x){
  object.size(x) |>
    print(units = "KiB")
})
# < 0.3 KiB

class(remote_df)

## common database interactions - fetching records from file ----
# all with dplyr translation under the hood

remote_df |>
  colnames()

remote_df |>
  head(10) |>
  dplyr::collect()

qq = remote_df |>
  dplyr::filter(id <= 20) |>
  dplyr::group_by(class) |>
  dplyr::summarise(
    total = sum(real),
    num = dplyr::n()
  )

class(qq)
dplyr::show_query(qq)
print(qq)
print(dplyr::collect(qq))

nrow(remote_df)

## ways to register streaming / virtual table ----

con = DBI::dbConnect(duckdb::duckdb())

# 1) command for streaming
duckdb::duckdb_read_csv(con, "test", "test.csv")
remote_df = dplyr::tbl(con, "test")

# 2) placing a view over the csv
DBI::dbExecute(con, "CREATE VIEW test AS SELECT * FROM read_csv_auto('test.csv')")
remote_df = dplyr::tbl(con, "test")

# 3) as an sql query
remote_df = dplyr::tbl(con, dplyr::sql("SELECT * FROM 'test.csv'"))

# all three appear to perform the same way

## materialise the data into duckdb (no longer streaming from file) ----

con = DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "CREATE TABLE test AS SELECT * FROM 'test.csv';")

# now data is inside duckdb
# by default this kind of connection creates an in-memory database
# so no memory saving with this approach

con = DBI::dbConnect(duckdb::duckdb())
# is equivalent to
con = DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")


# setting a location
con = DBI::dbConnect(duckdb::duckdb(), dbdir = "./db")
# filling the database
DBI::dbExecute(con, "CREATE TABLE test AS SELECT * FROM 'test.csv';")
# result is a 150 MB file on disk (smaller than 260 MB csv file)


## closing ----

# works as usual
DBI::dbDisconnect(con)

