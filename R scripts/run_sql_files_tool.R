################################################################################
# Run SQL files in sequence tool
# Simon Anastasiadis
# 2024-07-26
# 
# Requires a control file csv or xlsx with four columns:
# - folder_path: the folder the file is located in
# - file_name: the name of the file (including extension)
# - active: optional indicator to skip certain files: run (1/yes) or not (0/no)
# - order: optional sequence numbering to run files
# 
# Instructions:
# 1) Create a csv or xlsx control file with the columns given above
# 2) Open this script and edit only the section labelled user inputs
# 3) Source this script (Ctrl + Shift + S)
# 
################################################################################

## user inputs ------------------------------------------------------------ ----

# option 1: set to NA (no quotes), R will open a file selection window for you to choose file
# option 2: enter path (within quotes), if copying from Windows, replace \ with /
INSTRUCTIONS_FILE = "/nas/DataLab/MAA/MAA2023-46/social investment FVSV/Resources/sql_files_to_run.xlsx"

# start running at 7pm and stop at 6am (overrides DELAY_MINUTES)
NIGHT_MODE = TRUE
# manually set the number of minutes to wait
DELAY_MINUTES = 90

# use interrupt file, code stops after current iteration if this file is deleted
USE_INTERUPT_FILE = FALSE

## warnings and notes ----------------------------------------------------- ----
#' 
#' If using an Excel file as the input, R will only read the first sheet.
#' 
#' This tool may not work for all SQL files. It is possible to do things in SQL
#' files that will break R while still being acceptable SQL code. This script
#' aims to handle most cases, but does not handle everything.
#' 
#' R requires file paths to use / instead of \.
#' While Windows uses \ instead of /.
#' When copying file paths into R, you may need to change these manually.
#' 

## database connection ---------------------------------------------------- ----

connection_string = "DRIVER=ODBC Driver 18 for SQL Server; Trusted_Connection=Yes; TrustServerCertificate=Yes; "
connection_string = paste0(connection_string, "DATABASE=IDI_Clean_202406; ")
connection_string = paste0(connection_string, "SERVER=_SERVER_NAME_HERE_, _PORT_NUMBER_HERE_")

# confirm connection works
stopifnot(DBI::dbCanConnect(odbc::odbc(), .connection_string = connection_string))

## time stamped info messages --------------------------------------------- ----
#' Prints to console time of function call followed by msg.
#' If log path provided also appends to log.
#'
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

## data lab path handling ------------------------------------------------- ----
#' Adjusts file path to the difference between windows and R paths
#' within the data lab.
#' "I:/MAA20..." becomes "/nas/DataLab/MAA/MAA20..."
#' 
#' If copying from Windows, user must convert back-slashes to forward-slashes.
#' 
adjust_datalab_path_handling = function(file_name_and_path){
  stopifnot(is.character(file_name_and_path))
  
  # adjust if needed
  file_name_and_path = gsub("\\\\", "/", file_name_and_path)
  file_name_and_path = gsub("^[a-zA-Z]:/MAA20", "/nas/DataLab/MAA/MAA20", file_name_and_path)
  
  return(file_name_and_path)
}

## control file load and verify ------------------------------------------- ----
#' Loads input table and confirms its structure meets requirements for tool
#' 
load_and_verify_control_file = function(file_name_and_path){
  stopifnot(is.character(file_name_and_path))
  stopifnot(file.exists(file_name_and_path))
  
  extension = tools::file_ext(file_name_and_path)
  extension = tolower(extension)
  
  if (extension == "xls") {
    file_contents = readxl::read_xls(file_name_and_path, col_types = "text")
  } else if (extension == "xlsx") {
    file_contents = readxl::read_xlsx(file_name_and_path, col_types = "text")
  } else if (extension == "csv") {
    file_contents = read.csv(file_name_and_path, stringsAsFactors = FALSE, colClasses = "character")
  } else {
    stop(sprintf("Unaccepted file extension: %s", extension))
  }
  
  # standardize
  file_contents = as.data.frame(file_contents, stringsAsFactors = FALSE)
  colnames(file_contents) = tolower(trimws(colnames(file_contents)))
  
  # filter if applicable
  if("active" %in% colnames(file_contents)){
    keep_rows = tolower(file_contents$active) %in% c("1", "y", "yes", "true", "t")
    file_contents = file_contents[keep_rows,]
  }
  
  # sort if applicable
  if("order" %in% colnames(file_contents)){
    row_order = order(as.numeric(file_contents$order))
    file_contents = file_contents[row_order,]
  }
  
  # validate contents
  stopifnot("folder_path" %in% colnames(file_contents))
  stopifnot("file_name" %in% colnames(file_contents))
  
  # adjust for path differences
  file_contents$folder_path = sapply(file_contents$folder_path, adjust_datalab_path_handling, USE.NAMES = FALSE)
  
  # confirm file existence
  all_files_found = TRUE
  for(ii in 1:nrow(file_contents)){
    file_exists = file.exists(file.path(file_contents$folder_path[ii], file_contents$file_name[ii]))
    if(!file_exists){
      msg = paste("File", file_contents$file_name[ii], "not found")
      run_time_inform_user(msg)
      all_files_found = FALSE
    }
  }
  stopifnot(all_files_found)
  
  return(file_contents)
}

## interrupt file management ---------------------------------------------- ----
#' Handle the creation, checking, and removal of the interrupt file
#' if the interrupt file mechanism is being used.
#' 
interrupt_file = function(mode, in_use, location){
  stopifnot(is.logical(in_use))
  if(!in_use){
    return(TRUE)
  }
  
  stopifnot(is.character(mode))
  stopifnot(is.character(location))
  mode = tolower(mode)
  stopifnot(mode %in% c("create", "check", "remove"))
  stopifnot(file.exists(dirname(location)))
  
  interrupt_file_path = file.path(dirname(location), "sql runner underway.txt")
  
  if(mode == "create"){
    file_connection = file(interrupt_file_path, "w")
    writeLines("R will stop SQL runner tool after the next iteration if this file is deleted", file_connection)
    close(file_connection)
  }
  
  if(mode == "check"){
    return(file.exists(interrupt_file_path))
  }
  
  if(mode == "remove"){
    unlink(interrupt_file_path)
  }
  
  return(TRUE)
}

## read file and prepare code --------------------------------------------- ----
#' Reads in sql file and prepares for running.
#' Preparation includes removal of comments and splitting on GO and ;
#' 
#' Line numbers for the original file are returned to aid reporting.
#' 
read_and_prepare_sql_code = function(file_name_and_path){
  stopifnot(is.character(file_name_and_path))
  stopifnot(tools::file_ext(file_name_and_path) == "sql")
  
  sql_code = readLines(file_name_and_path)
  sql_code = trimws(sql_code)
  sql_code = tolower(sql_code)
  sql_code = paste(sql_code, collapse = "\n")
  
  # 'go' inside comments becomes '_g_o_'
  # /\\* = the text /*
  # ((?:[^*]|\\*[^/])*) = any text that is not */
  # \\*/ = the text */
  # \n = new line
  # So this searches for the pattern go on a line by itself
  # Where a comment starts before it and ends after it.
  in_code = ""
  while(sql_code != in_code){
    in_code = sql_code
    sql_code = gsub('/\\*((?:[^*]|\\*[^/])*)\ngo\n((?:[^/]|/[^\\*])*)\\*/', '/*\\1\n_g_o_\n\\2*/', in_code)
  }
  
  # break into batches
  sql_code = strsplit(sql_code, "\ngo")
  sql_code = unlist(sql_code)
  
  # calculate start and end lines
  sql_code_short = gsub("\n", "", sql_code)
  batch_lines = nchar(sql_code) - nchar(sql_code_short) + 1
  batch_breaks = c(1, 1 + cumsum(batch_lines))
  
  # start and end
  batch_starts = batch_breaks[1:(length(batch_breaks)-1)]
  batch_ends = batch_breaks[2:length(batch_breaks)]
  
  sql_code = trimws(sql_code)
  
  return(list(code = sql_code, start_lines = batch_starts, end_lines = batch_ends))
}

## run sql files tool ----------------------------------------------------- ----
#' Run multiple SQL files in sequence as specified by a control file
#' 
run_sql_files_tool = function(
    instructions_file,
    db_connection_string,
    use_interrupt_file = FALSE,
    night_mode = FALSE,
    delay_minutes = 0
){
  stopifnot(is.na(instructions_file) | is.character(instructions_file))
  stopifnot(is.logical(use_interrupt_file))
  stopifnot(is.logical(night_mode))
  stopifnot(is.na(delay_minutes) | is.numeric(delay_minutes))
  stopifnot(DBI::dbCanConnect(odbc::odbc(), .connection_string = db_connection_string))

  ## log ----
  
  # request path if needed
  if(is.na(instructions_file)){
    instructions_file = file.choose()
  }
  # ensure valid path
  instructions_file = adjust_datalab_path_handling(instructions_file)
  
  # log file
  log_file_path = as.character(Sys.time())
  log_file_path = substr(log_file_path, 1, 19)
  log_file_path = gsub(":", "", log_file_path)
  log_file_path = paste0("log run SQL tool ", log_file_path, ".txt")
  log_file_path = file.path(dirname(instructions_file), log_file_path)
  
  ## setup ----
  
  run_time_inform_user("RUN SQL FILES TOOL BEGUN", log_file_path)
  # load and check control file
  control_df = load_and_verify_control_file(instructions_file)
  
  # create interruption file
  interrupt_file("create", use_interrupt_file, instructions_file)
  # report
  msg = paste(nrow(control_df), "scripts to be run by tool")
  
  ## report delay ----
  
  if(night_mode){
    start_time = paste(Sys.Date(), "19:00:00 NZST")
    delay_minutes = as.numeric(as.POSIXct(start_time) - Sys.time(), units = "mins")
    delay_minutes = max(delay_minutes, 0)
    end_time = paste(Sys.Date() + 1, "05:00:00 NZST")
  }
  
  if(delay_minutes != 0){
    msg = as.character(Sys.time() + 60 * delay_minutes)
    msg = substr(msg, 1, 19)
    msg = paste("Tool waiting until", msg)
    run_time_inform_user(msg, log_file_path)
    
    run_time_inform_user("Entering sleep", log_file_path)
    Sys.sleep(60 * delay_minutes)
    run_time_inform_user("Resuming from sleep", log_file_path)
  }
  
  ## iterate over files ----
  
  for(rr in 1:nrow(control_df)){
    ## check early stop conditions ----
    
    # interrupt file removal
    if(!interrupt_file("check", use_interrupt_file, instructions_file)){
      run_time_inform_user("Interupting due to file removal", log_file_path)
      break
    }
    
    # night mode but now day time
    if(night_mode && end_time < Sys.time()){
      run_time_inform_user("Interupting due to morning", log_file_path)
      break
    }
    
    ## begin next file ----
    
    this_folder = control_df$folder_path[rr]
    this_file = control_df$file_name[rr]
    # read code (list with 3 components: code, start_lines, end_lines)
    batches = read_and_prepare_sql_code(file.path(this_folder, this_file))
    # inform user
    msg = paste("Running file", this_file, "in", length(batches$code), "batches")
    run_time_inform_user(msg, log_file_path)
    # database connect
    db_connection = DBI::dbConnect(odbc::odbc(), .connection_string = db_connection_string)
    
    any_failure = 0
    
    ## process each batch ----
    for(ii in 1:length(batches$code)){
      this_code = batches$code[ii]
      this_start = batches$start_lines[ii]
      this_end = batches$end_lines[ii]
      
      # pause
      Sys.sleep(1)
      
      # skip if prior error
      if(any_failure != 0){
        msg = sprintf("    Skipping lines %4d to %4d due to prior error", this_start, this_end)
        run_time_inform_user(msg, log_file_path)
        next
      }
      
      # log start
      msg = sprintf("    Running batch %2d, lines %4d to %4d", ii, this_start, this_end)
      run_time_inform_user(msg, log_file_path)
      
      
      # attempt execution
      any_failure = 1
      tryCatch(
        # try
        {
          # prefix nocount
          this_code = paste("set nocount on;\n", this_code)
          
          result = DBI::dbExecute(db_connection, this_code, immediate = TRUE)
          any_failure = 0
        },
        # catch
        error = function(e){
          msg = "Error occurred during execution"
          run_time_inform_user(msg, log_file_path)
          run_time_inform_user(as.character(e), log_file_path)
        }
      )
      
    } # end of all batches
    
    ## end of file ----
    
    msg = ifelse(
      any_failure == 0,
      paste("Successful completion of file", this_file),
      paste("Haulting execution of file", this_file, "due to errors")
    )
    run_time_inform_user(msg, log_file_path)
    # disconnect before next file to clear temporary tables
    DBI::dbDisconnect(db_connection)
    
  } # end of all files
  
  ## tidy up ----
  interrupt_file("remove", use_interrupt_file, instructions_file)
  
}

## execute ---------------------------------------------------------------- ----

run_sql_files_tool(
  instructions_file = INSTRUCTIONS_FILE,
  db_connection_string = connection_string,
  use_interrupt_file = USE_INTERUPT_FILE,
  night_mode = NIGHT_MODE,
  delay_minutes = DELAY_MINUTES
)

## test list ----
#' 
#' logs get created
#' logs match console output
#' delay works
#' night mode works
#' interrupt_file = FALSE works
#' interrupt_file = TRUE stops on deletion
#' instructions file as NA
#' instructions file as full path string
#' error checks occur prior to sleep
#' 
#' run_time_inform_user prints and logs
#' adjust_datalab_path_handling converts paths if/as required
#' load_and_verify_control_file filters files
#' load_and_verify_control_file orders files
#' load_and_verify_control_file corrects paths
#' load_and_verify_control_file errors on incorrect file or folder names
#' read_and_prepare_sql_code batches code
#' read_and_prepare_sql_code produces start and end line numbers
#' 
#' Multiple GO statements within comments
#' 
#' KNOWN ISSUES
#' Temporary tables created in earlier chunks may no be available in later chunks
#' Currently testing solution: SET NOCOUNT ON; and dbExecute(immediate = TRUE)
#' 
