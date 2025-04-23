
FOLDER = "/nas/DataLab/MAA/MAA2023-46/social investment FVSV/Analysis"
delay_minutes = 60

db_connection_string = "DRIVER=ODBC Driver 18 for SQL Server; Trusted_Connection=Yes; TrustServerCertificate=Yes;"
db_connection_string = paste(db_connection_string, "DATABASE=IDI_Clean_202406;")
db_connection_string = paste(db_connection_string, "SERVER=_SERVER_NAME_HERE_, _PORT_NUMBER_HERE_")

## print with time stamp -------------------------------------------------- ----

run_time_inform_user = function(msg, log = NA) {
  stopifnot(is.character(msg))
  now = as.character(Sys.time())
  now = substr(now, 1, 19)
  msg = paste0(now, " | ", msg)
  cat(msg, "\n")
  
  if(!is.na(log)){
    write(msg, log, append = TRUE)
  }
}

## try run file ----------------------------------------------------------- ----

try_run_file = function(file){
  
  setwd(FOLDER)
  run_time_inform_user("----------------------------------------")
  run_time_inform_user(file)
  try(
    source(file)
  )
  
}

## try run simple sql ----------------------------------------------------- ----
# does not handle GO statements

try_run_sql = function(file){
  
  setwd(FOLDER)
  run_time_inform_user("----------------------------------------")
  run_time_inform_user(file)
  try({
    sql_code = readLines(file)
    sql_code = trimws(sql_code)
    sql_code = tolower(sql_code)
    sql_code = paste(sql_code, collapse = "\n")
    
    db_connection = DBI::dbConnect(odbc::odbc(), .connection_string = db_connection_string)
    DBI::dbExecute(db_connection, sql_code, immediate = TRUE)
    DBI::dbDisconnect(db_connection)
  })
}

## delay ------------------------------------------------------------------ ----

run_time_inform_user("delaying")
Sys.sleep(60 * delay_minutes)
run_time_inform_user("resuming")

## run files in order ----------------------------------------------------- ----

# try_run_file("run_assembly_2019.R")
# try_run_file("run_assembly_2020-2023.R")
# try_run_file("tidy_variables_2019.R")
# try_run_file("tidy_variables_2020-2023.R")
# try_run_sql("summarise_network.sql")
# try_run_sql("ready_combined_dataset.sql")

try_run_file("test_nested_clustering.R")

## conclude --------------------------------------------------------------- ----

run_time_inform_user("----------------------------------------")
run_time_inform_user("done")
run_time_inform_user("----------------------------------------")

## optional --------------------------------------------------------------- ----
# check if R script is valid before executing

is_valid_r_text = function(text){
  text = as.character(text)
  pass = tryCatch(
    {parse(text = text); TRUE},
    error = function(e){return(FALSE)}
  )
  return(pass)
}

is_valid_r_file = function(file){
  stopifnot(file.exists(file))
  pass = tryCatch(
    {parse(file = file); TRUE},
    error = function(e){return(FALSE)}
  )
  return(pass)
}
