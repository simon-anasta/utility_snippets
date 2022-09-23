library(DBI)
library(odbc)
library(RSQLite)
library(tidyverse)
library(magrittr)
library(dbplyr)

# setup database
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbListTables(con)

# load tables into database
data("mtcars")
data("diamonds")

dbWriteTable(con, "cars", mtcars)
dbWriteTable(con, "diamonds", diamonds)

# check tables in 
dbListTables(con)

remote_table = tbl(con, "cars")
remote_table = tbl(con, "diamonds")

# check is remote
class(remote_table)

# column names
colnames(remote_table)
# check data types
remote_table %>% head() %>% collect() %>% summary()

remote_table %>% head() %>% show_query()
