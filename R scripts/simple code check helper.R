#
# Simple code check helper
# 2022-11-28
# Simon Anastasiadis
#
# Instructions:
# Press Ctrl + Shift + F10
# to reset R
# Press Ctrl + Shift + S or click Source
# to run the helper
#

## setup ------------------------------------------------------------

library(dplyr)
library(rstudioapi)

CONFIG = list(
  accept_exts = c("do", "R", "sql", "txt", "sas"),
  keyword = "\\b[0-9\\.][0-9,\\.]+\\b"
)


## get directory ----------------------------------------------------

input_dir = selectDirectory(
  caption = "Select Directory to check",
  label = "Select",
  path = getActiveProject()
)

all_files = dir(path = input_dir, recursive = TRUE)
extensions = tools::file_ext(all_files)

## create output ----------------------------------------------------

# setup
output_df = data.frame(stringsAsFactors = FALSE)
options(warn = -1)

for(each_file in all_files){
  # unexcepted extension
  if(! tools::file_ext(each_file) %in% CONFIG$accept_exts){
    output_df = rbind(
      output_df,
      as.data.frame(list(
        msg = "file skipped",
        file = each_file,
        line = 0,
        contents = paste("can not accept file format"))
      )
    )
    next
  }
  
  # examine file
  line_number = 0
  out_lines = 0
  this_file_df = data.frame(stringsAsFactors = FALSE)
  
  # read file
  con = file(paste0(input_dir, "/", each_file), "r")
  while( TRUE ){
    line_number = line_number + 1
    line = readLines(con, n = 1)
    # stop at end of document
    if(length(line) == 0){
      break
    }
    # record lines with matching keywords
    if(grepl(CONFIG$keyword, line)){
      out_lines = out_lines + 1
      this_file_df = rbind(
        this_file_df,
        as.data.frame(list(
          msg = "match",
          file = each_file,
          line = line_number,
          contents = line)
        )
      )
    }
  }
  # done reading file
  close(con)
  # record file to output df
  output_df = rbind(
    output_df,
    as.data.frame(list(
      msg = "file checked",
      file = each_file,
      line = 0,
      contents = paste(out_lines, "lines found with matches of", line_number, "lines read"))
    ),
    this_file_df
  )
}

## output -----------------------------------------------------------

options(warn = 0)

output_dir = selectDirectory(
  caption = "Select location to save",
  label = "Select",
  path = input_dir
)

file_name = paste0(output_dir, "/simple code check", as.character(Sys.time()), ".csv")
file_name = gsub(":", "_", file_name)
write.csv(output_df, file_name)

