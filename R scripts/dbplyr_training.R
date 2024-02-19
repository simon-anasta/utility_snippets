#####################################################################
# S.C.N. - dbplyr to work between R and SQL
# 2024-02-19
# Simon Anastasiadis
# 
#####################################################################

library(dbplyr)
library(dplyr)

## creating a connection -------------------------------------------- ----

conn_str = "Driver=ODBC Driver 17 for SQL Server; SERVER=_____; DATABASE=____; Trusted_Connection=Yes"
db_conn = DBI::dbConnect(odbc::odbc(), .connection_string = conn_str, timeout = 10)
DBI::dbDisconnect(db_conn)


db_conn = DBI::dbConnect(
  odbc::odbc(),
  driver = "ODBC Driver 17 for SQL Server",
  server = "____",
  database = "____",
  trusted_connection = "Yes"
)
DBI::dbDisconnect(db_conn)  

# database selection
# equivalent to SQL command:
#
# USE database_name
# GO


## troubleshooting:
# file not found = driver does not exist, either typo or different version
# login timeout expired = server does not exist or don't have permission
# cannot open database = database does not exist or you don't have permission to access
# login failed for user = lacking credentials or trusted connection

## connecting to SQL tables ----------------------------------------- ----
#
# any data shown on screen has been randomly generated
# [database_name].[schema_name].[table_name_1]
# [database_name].[schema_name].[table_name_2]

# table in connected database, default schema
remote_table = tbl(db_conn, "table_name")

# table in connected database, custom schema
remote_table = tbl(db_conn, in_schema("schema_name", "table_name"))

# table in connected server, and database and schema
remote_table = tbl(db_conn, in_schema(sql("database.schema_name"), "table_name"))


# demonstrating connection
remote_tbl1 = tbl(db_conn, in_schema(sql("[database_name].[schema_name]"),"table_name_1"))
remote_tbl2 = tbl(db_conn, in_schema(sql("[database_name].[schema_name]"),sql("[table_name_2]")))

# alternative with arbitrary starting query
sql_query = "SELECT * FROM [database_name].[schema_name].[table_name_1]"
remote_table3 = tbl(db_conn, dbplyr::sql(sql_query))
# works because a remote_table is implemented
# as a list with two components: the connection and the query.


## basic translation ------------------------------------------------ ----

colnames(remote_tbl1)
colnames(remote_tbl2)

tmp = remote_tbl1 %>%
  select(uid, event_id_nbr, start_date, birth_year) %>%
  mutate(age = 2023 - birth_year) %>%
  filter(uid %% 100 == 0) %>%
  left_join(remote_tbl2, by = c("event_id_nbr" = "event_id")) %>%
  group_by(type_code, age) %>%
  summarise(num = n(), .groups = "drop")

# review the SQL translation
show_query(tmp)
# not a beautiful query
# written by a computer to be read by a computer


## translation tricks ----------------------------------------------- ----

# if term not defined - left untranslated
tmp = remote_tbl1 %>%
  mutate(new_col = SPECIAL_FUNCTION(birth_year))

show_query(tmp)


# sql() can be used to bypass translation
tmp = remote_tbl1 %>%
  mutate(new_col = sql("as.character(birth_year)"))

show_query(tmp)


# sequencing of mutates required

# works in R, may not work in SQL via dbplyr translation
tmp = remote_tbl1 %>%
  mutate(age = 2023 - birth_year,
         age_group = ifelse(age > 15, "working", "child"))

# works in R and will work in SQL dbplyr translation
tmp = remote_tbl1 %>%
  mutate(age = 2023 - birth_year) %>%
  mutate(age_group = ifelse(age > 15, "working", "child"))


# restricted to simple flows

# this will fail
tmp = remote_tbl1 %>%
  left_join(
    # subquery
    remote_tbl2 %>%
      select(event_id, type_code),
    by = c("event_id_nbr" = "event_id")
  )

# better approach with same idea
setup = remote_tbl2 %>%
  select(event_id, type_code)

tmp = remote_tbl1 %>%
  left_join(
    # subquery
    setup,
    by = c("event_id_nbr" = "event_id")
  )


## working across R and SQL ----------------------------------------- ----
#
# R is well suited for complex statistical processing
# SQL is well suited for processing large datasets out of memory
#
# This example uses a loop in R to progressively fetch data from
# SQL and filter to a subset using regex for further analysis.

audit_names = c("audit_tbl_202301", "audit_tbl_202302", "audit_tbl_202303",
                "audit_tbl_202304", "audit_tbl_202305", "audit_tbl_202306")

fetch_query = "
SELECT [session_server_principal_name], [statement]
FROM [Audit_db].[dbo].[{audit}]
WHERE [database_name] = 'ibuldd_clean'
"

output_list = list()

for (audit in audit_names) {
  query = glue::glue(fetch_query)
  
  result = DBI::dbGetQuery(db_conn, query)
  
  result = dplyr::filter(grepl("IDI_Clean_20[0-9][0-9]", statement))
  
  if (nrow(result) > 0) {
    output_list = c(output_list, list(result))
  }
}

audit_output = dplyr::bind_rows(output_list)


## DBI package ------------------------------------------------------ ----
#
# Likely already in use if using dbplyr

# get back a list of all tables in the database (includes admin tables)
DBI::dbListTables(db_conn)
# DBI::dbListTables(db_conn)

# run a query and bring back results to R
DBI::dbGetQuery()
# local_results = DBI::dbGetQuery(db_conn, "SELECT TOP 10 * FROM my_table")

# execute code on the server
DBI::dbExecute()
# DBI::dbExecute("DROP TABLE IF EXISTS my_schema.my_table")

# used for writing tables from R into the database
DBI::dbWriteTable()
DBI::Id()

## programming with dbplyr ------------------------------------------ ----

# common with writing scripts
remote_table %>%
  mutate(new_col = old_col * 2) %>%
  select(-old_col)


# programming - does not work
my_function = function(df, in_col, out_col){
  df %>%
    mutate(out_col = in_col * 2) %>%
    select(-in_col)
}
my_function(remote_table, old_col, new_col)


# programming - does work
my_function = function(df, in_col, out_col){
  df %>%
    mutate(!!sym(out_col) = !!sym(in_col) * 2) %>%
    select(-all_of(in_col))
}
my_function(remote_table, "old_col", "new_col")
# sym and !! are an rlang approach
# there are other options see "programming with dplyr"


## options for experimenting ---------------------------------------- ----

# in memory database
db_conn <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
dbListTables(db_conn)

# load tables into database
data("mtcars")
dbWriteTable(con, "cars", mtcars)

remote_table = tbl(db_conn, "cars")


# simulated connection
data(starwars)

# pick your simulated connection type (there are many options, not just what I have shown here)
remote_df = tbl_lazy(starwars, con = simulate_mssql())
remote_df = tbl_lazy(starwars, con = simulate_mysql())
remote_df = tbl_lazy(starwars, con = simulate_postgres())

# not all translations are defined
remote_df %>%
  mutate(substring_col = str_extract(name, "Luke")) %>%
  show_query()


## disconnect once done --------------------------------------------- ----

DBI::dbDisconnect(db_conn)

## resources -------------------------------------------------------- ----

# code
#
# https://github.com/nz-social-wellbeing-agency/idi_exemplar_project
# https://github.com/nz-social-wellbeing-agency/dataset_assembly_tool/tree/master

# documentation
#
# https://swa.govt.nz/publications/IDI-Exemplar-Project-guidance
# https://swa.govt.nz/publications/Accelerating-dataset-assembly-guidance

# projects
# SWA GitHub Debt to Government (x3)
# SWA GitHub Administrative households
