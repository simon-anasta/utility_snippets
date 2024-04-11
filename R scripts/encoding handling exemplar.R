###############################################################################
#' File read, handling different encodings & special characters
#' Simon Anastasiadis
#' 2024-04-12
#'
#' Notes:
#' - An encoding is a way to represent characters in binary. Windows-1252,
#'    ASCII, and UTF-8 are common encodings.
#' - When a file contains bytes that do not match an accepted character,
#'    R will error. This is often caused by non-alpha-numeric characters.
#'    Non-printing characters can similarly cause errors.
#' - Files can be read in binary mode or text mode.
#'    Different errors occur in the two modes. So try both. For this learning
#'    text mode gave errors where binary mode gave warnings, so a more robust
#'    solution was possible when reading in binary mode.
#' - Within `readLines`, we use `skipNul = TRUE` to avoid errors on nulls.
#'    This can lead input lines to return two output lines: character(0) and
#'    that input line. Hence we require `nchar != 0`.
#' - Attempting to process character strings containing invalid encoding fails.
#'    For example, calling `nchar` on a string with invalid encoding errors.
#'    `validEnc` returns FALSE if a string contains any invalid encodings.
#' - Conversion between encodings is possible. `iconv` can be used for this.
#'    No need to specify the `from` argument. Essential to specify to `sub`
#'    argument. `sub = ""` will replace any character that can not be converted
#'    with the empty string.
#' - When reading delimited tables, `strsplit` will return one fewer value than
#'    required if the final value is a delimiter.
#'    For example `strsplit("a|b|c|","|")` will return 3 values, not 4.
#'
###############################################################################

## guess file delimiter -------------------------------------------------- ----

guess_delim = function(header_line, non_delim_characters = "abcdefghijklmnopqrstuvwxyz1234567890_ "){
  
  # remove characters not used for delimiters
  pattern = paste0("[", non_delim_characters, "]")
  header_line = gsub(pattern, "", header_line, ignore.case = TRUE)
  
  # list all characters
  individual_characters = strsplit(header_line, "")[[1]]
  
  # most common character
  table_characters = table(individual_characters)
  max_count = max(table_characters)
  delim = names(table_characters)[max_count == table_characters]
  
  # keep first in case of multiple characters
  delim = delim[1]
  
  return(delim)
}

## try_read_lines -------------------------------------------------------- ----

try_read_lines = function(con, n, encoding){
  
  out = sapply(
    rep("", n),
    function(x){
      try({x = readLines(con, n = 1, skipNul = TRUE, encoding = encoding)}, silent = TRUE)
      return(x)
    }
  )
  
  out = unlist(out)
  out = out[!is.na(out)]
  
  errors = !validEnc(out)
  errors_position = (1:length(out))[errors]
  
  out = iconv(out, to = "ascii", sub = "")
  out = out[sapply(out, length) == 1]
  out = out[sapply(out, nchar) != 0]
  # return pair, error position and read lines
  return(list(errors = errors_position, line = out))
}

## begin processing data file -------------------------------------------- ----

# get encoding
possible_encodings = readr::guess_encoding(file_path)
best_encoding = possible_encodings$confidence == max(possible_encodings$confidence)
encoding = possible_encodings$encoding[best_encoding][1]

# connect to file
# con = file(file_path, "r", encoding = encoding)
con = file(file_path, "rb", encoding = encoding)

# read first / header line
header_line = readLines(con, n = 1, skipNul = TRUE, encoding = encoding)
header_line = iconv(header_line, to = "ascii", sub = "")

# determine delimiter
delim = guess_delim(header_line)

# column names
column_names = strsplit(header_line, delim, fixed = TRUE)[[1]]
column_names = trimws(column_names)

## read through file ----------------------------------------------------- ----
  
line_num = 0
error_num = 0
increment = 5000
max_records = 1000000
  
while ( TRUE ) {
  # read next line(s)
  errors_line = try_read_lines(con, n = increment, encoding = encoding)
  line = errors_line$line
  errors = errors_line$errors
    
  # report encoding errors
  for(ee in errors){
    print(sprintf("Error: Line %d invalid encoding found", ee + line_num))
  }
  error_num = error_num + length(errors)
    
  # stop if no more lines
  if ( length(line) == 0 ) { break }
   
  # split line
  split_line = strsplit(line, delim, fixed = TRUE)
    
  # handle splitter at end of line
  split_line = lapply(
    split_line,
    function(x){
      if(length(x) == length(column_names) - 1){
        x = c(x, "")
      }
      return(x)
    }
  )
    
  # drop short lines
  right_length = sapply(split_line, length) == length(column_names)
  errors = (1:length(split_line))[!right_length]
  for(ee in errors){
    print(sprintf("Error: Line %d incorrect number columns", ee + line_num))
  }
  error_num = error_num + length(errors)
  # dicard errors
  split_line = split_line[right_length]
    
  # name all components
  split_line = lapply(
    split_line,
    function(x){
      names(x) = column_names
      return(x)
    }
  )
    
  # bind to data.frame
  line_df = dplyr::bind_rows(split_line)
    
  ## process line
  #
  # whatever is required goes here
  #
    
  # report on lines processed
  line_num = line_num + length(line)
  
  if(line_num %% reporting == 0){
    print(sprintf("At line %8d", line_num))
  }
  
  # exit if max lines processed
  if(0 < max_records & max_records <= line_num){ break }

} # end file read
  
## conclude -------------------------------------------------------------- ----
  
# disconnect from file
close(con)
# report
print(sprintf("%d errors during file read", error_num))
print(sprintf("%d total rows read", line_num))
