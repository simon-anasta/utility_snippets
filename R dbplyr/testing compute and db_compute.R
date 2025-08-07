# Testing compute and db_compute commands in dbplyr
# Simon Anastasiadis
# 2022-03-10
#

setwd("~/Network-Shares/DataLabNas/MAA/MAA2020-01/debt to government_Phase3/data exploration")

library(DBI)
library(dbplyr)
library(dplyr)

connection_string = "Driver=ODBC Driver 17 for SQL Server; Trusted_Connection=YES; Server={server_details},{port_number};Database={database_name}"
db_connection <- DBI::dbConnect(odbc::odbc(), .connection_string = connection_string)

remote_table = dplyr::tbl(db_connection, from = dbplyr::in_schema("[IDI_Clean_20201020].[data]", "personal_detail"))

r2 = remote_table %>%
  head()

r2 %>% show_query()

r3 = r2 %>% compute()

r3 %>% show_query()

r4 = db_compute(
  con = db_connection,
  table = in_schema("[IDI_Sandpit].[DL-MAA2020-01]","tmp_tmp"),
  sql = (sql_render(r2)),
  temporary = FALSE
  )

r4 = dplyr::tbl(db_connection, from = in_schema("[IDI_Sandpit].[DL-MAA2020-01]","tmp_tmp"))


DBI::dbDisconnect(db_connection)

# another approach from stackoverflow:
# this can do done using `compute` rather than `db_compute`
compute(my_frame,
        in_schema(sql("mydb.dbo"), "mynewtable"), 
        FALSE)

