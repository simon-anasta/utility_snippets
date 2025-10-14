################################################################################
# Support tool for mapping dependencies within an R project
# 2025-10-14
# 
# Use demonstrated at end of script.
# Main function is: find_function_use_within_functions
# Plotting output as network helps map dependencies and interactions.
# 
# Not perfect, but helpful alternative to manual mapping.
################################################################################

## strip comments from line ----------------------------------------------- ----
# Given a line of R code, return the line with comments removed.
# Ignores # within strings. Does not ignore # within back-ticks.
# 
strip_comment = function(line) {
  stopifnot(is.character(line))
  stopifnot(length(line) == 1)
  
  # exit early if no #
  if(!grepl("#", line)){
    return(line)
  }
  
  # setup
  in_single <- FALSE
  in_double <- FALSE
  escaped <- FALSE
  
  split_line = strsplit(line, "")[[1]]
  
  
  for(ii in seq_along(split_line)){
    
    this_char = split_line[ii]
    
    if(escaped){
      escaped = FALSE
      next
    }
    
    if(this_char == "\\" && (in_single || in_double)){
      escaped = TRUE
    }
    
    if(this_char == "'" && !(in_double || escaped)){
      in_single = !in_single
    }
    
    if(this_char == "\"" && !(in_single || escaped)){
      in_double = !in_double
    }
    
    if(this_char == "#" && !(in_single || in_double)){
      return(substr(line, 1, ii - 1))  # strip comment
    }
    
  }
  # no comment found
  return(line)
}

## remove comments -------------------------------------------------------- ----
# Given code lines (one line per vector entry), removes comments from every
# line. Avoids removal of # within text strings.
# 
remove_comments = function(code_lines){
  stopifnot(is.character(code_lines))
  
  # line start, even number of quotes, # comment, then line end
  reg_expression = "^(\\s*(?:[^'\"]*(?:'[^']*'|\"[^\"]*\")?)*?)(#.*)$"
  
  code_lines = sapply(code_lines, strip_comment, USE.NAMES = FALSE)
}

## find all bracket pairs ------------------------------------------------- ----
# Given a file, returns all the open-close pairs and their internal depth within
# the file. Everywhere not returned is depth zero.
# Note `open` and `close` must be regex ready (e.g. contain \\ if applicable).
# Results may seem odd where multiple open or close occur on the same line.
#
find_bracket_pairs = function(file_name, open = "\\{", close = "\\}"){
  stopifnot(file.exists(file_name))
  stopifnot(is.character(open), is.character(close))
  
  contents = readLines(file_name)
  contents = remove_comments(contents)
  line_length = sapply(contents, nchar, USE.NAMES = FALSE)
  len_wout_open = sapply(gsub(open, "", contents), nchar, USE.NAMES = FALSE)
  num_open_raw = line_length - len_wout_open
  len_wout_close = sapply(gsub(close, "", contents), nchar, USE.NAMES = FALSE)
  num_close_raw = line_length - len_wout_close
  
  # remove open and close pairs on same line
  num_open = pmax(num_open_raw - num_close_raw, 0)
  num_close = pmax(num_close_raw - num_open_raw, 0)
  
  bracket_depth_per_line = cumsum(num_open) - cumsum(num_close)
  
  # data frames for joining
  open_df = data.frame(
    open_line = which(num_open != 0),
    open_depth = bracket_depth_per_line[which(num_open != 0)]
  )
  
  close_df = data.frame(
    close_line = which(num_close != 0),
    close_depth = bracket_depth_per_line[which(num_close != 0)]
  )
  
  # add back multiple open on same line
  adjuster = 1
  while(any(num_open > adjuster)){
    num_open_tmp = pmax(num_open - adjuster, 0)
    bracket_depth_per_line_tmp = pmax(bracket_depth_per_line - adjuster, 0)
    open_df_tmp = data.frame(
      open_line = which(num_open_tmp != 0),
      open_depth = bracket_depth_per_line_tmp[which(num_open_tmp != 0)]
    )
    open_df = dplyr::bind_rows(open_df, open_df_tmp)
    adjuster = adjuster + 1
  }
  open_df = dplyr::arrange(open_df, open_line, open_depth)
  
  # find closure
  df = dplyr::cross_join(open_df, close_df)
  df = dplyr::filter(df, open_line < close_line, open_depth > close_depth)
  df = dplyr::group_by(df, open_line, open_depth)
  df = dplyr::summarise(df, close_line = min(close_line), .groups = "drop")
  
  return(df)
}

## find functions within file --------------------------------------------- ----
# Given a file, find all function creation within the file. Return a data
# frame with file, function, and line number.
# 
find_functions_within_file = function(file_name){
  stopifnot(file.exists(file_name))
  
  # line start, function-name, assignment (= or <-), then 'function'
  reg_expression = "^\\s*(.+?)\\s*(?:=|<-)\\s*function\\s*\\("
  
  contents = readLines(file_name)
  contents = remove_comments(contents)
  raw_matches = stringr::str_match_all(contents, reg_expression)
  matches = sapply(
    raw_matches,
    function(x){ifelse(is.null(x[,2]),NULL,x[,2])},
    USE.NAMES = FALSE
  )
  
  found_lines = which(!is.na(matches))
  found_functions = matches[!is.na(matches)]
  
  out_df = data.frame(
    file_name = basename(file_name),
    function_name = found_functions,
    start_line = found_lines,
    stringsAsFactors = FALSE
  )
  
  bracket_pairs = find_bracket_pairs(file_name)
  
  out_df = dplyr::cross_join(out_df, bracket_pairs)
  out_df = dplyr::filter(out_df, start_line <= open_line)
  out_df = dplyr::group_by(out_df, file_name, function_name, start_line)
  out_df = dplyr::mutate(out_df, min_open = min(open_line))
  out_df = dplyr::ungroup(out_df)
  out_df = dplyr::filter(out_df, open_line == min_open | is.na(min_open))
  out_df = dplyr::select(
    out_df, file_name, function_name, start_line,
    open_line, open_depth, close_line
  )
  
  return(out_df)
}

## find functions within directory ---------------------------------------- ----
# Given a directory, find all functions within all files in the directory.
# Return a data frame.
# 
find_function_within_directory = function(dir_path){
  stopifnot(dir.exists(dir_path))
  
  all_files = dir(dir_path, full.names = TRUE)
  
  all_functions = lapply(all_files, find_functions_within_file)
  all_functions = dplyr::bind_rows(all_functions)
  
  return(all_functions)
}

## find function use within file ------------------------------------------ ----
# Finds all line numbers where function_name appears within a file.
# This includes function creation.
# 
find_function_use_within_file = function(file_name, function_name){
  stopifnot(file.exists(file_name))
  stopifnot(is.character(function_name))
  # special character check
  if(!grepl(function_name, function_name)){
    stop("Function ", function_name, " is not regex compatible")
  }
  
  # function name with word boundaries, not followed by = or <-
  reg_expression = paste0("\\b", function_name, "\\b(?!\\s*(=|<-))")
  
  contents = readLines(file_name)
  contents = remove_comments(contents)
  matches = grepl(reg_expression, contents, perl = TRUE)
  found_lines = which(matches)
  
  out_df = data.frame(
    using_file_name = basename(file_name),
    used_function_name = function_name,
    used_line_number = c(found_lines, -1), # -1 handles no-matches case
    stringsAsFactors = FALSE
  )
  out_df = dplyr::filter(out_df, used_line_number != -1)
  
  return(out_df)
}

## find function use within directory ------------------------------------- ----
# Given a directory and a function name, find all use of that function within
# files in that directory. Return a data frame.
# 
find_function_use_within_directory = function(dir_path, function_name){
  stopifnot(dir.exists(dir_path))
  stopifnot(is.character(function_name))
  
  # process
  all_files = dir(dir_path, full.names = TRUE)
  
  all_use = lapply(all_files, find_function_use_within_file, function_name = function_name)
  all_use = dplyr::bind_rows(all_use)
  
  return(all_use)
}

## find all function use within directory --------------------------------- ----
# Given a directory and a vector of functions, find the use of all functions
# within files in that directory. Return a data frame.
# 
find_all_function_use_within_directory = function(dir_path, all_functions){
  stopifnot(dir.exists(dir_path))
  stopifnot(is.character(all_functions))
  
  # warning
  if(any(duplicated(all_functions))){
    dupes = unique(all_functions[duplicated(all_functions)])
    warning(
      "muddled results due to duplicate function names\nduplicates: ",
      paste(dupes, collapse = ", ")
    )
    all_functions = unique(all_functions)
  }
  
  # process
  all_use = lapply(all_functions, find_function_use_within_directory, dir_path = dir_path)
  all_use = dplyr::bind_rows(all_use)
  
  return(all_use)
}

## find function use within functions ------------------------------------- ----
# Searches all files (assumed to be R files) within a directory for functions
# and function use. Returns a data frame describing each function and any
# functions it uses.
# 
find_function_use_within_functions = function(dir_path){
  stopifnot(dir.exists(dir_path))
  
  all_functions = find_function_within_directory(dir_path)
  all_use = find_all_function_use_within_directory(dir_path, all_functions$function_name)
  
  df = dplyr::inner_join(
    all_functions,
    all_use,
    by = c("file_name" = "using_file_name"),
    relationship = "many-to-many"
  )
  df = dplyr::filter(df, open_line <= used_line_number & used_line_number <= close_line)
  df = dplyr::filter(df, function_name != used_function_name | start_line != used_line_number)
  df = dplyr::select(df, file_name, function_name, used_function_name, used_line_number)
  
  df = dplyr::left_join(all_functions, df, by = c("file_name", "function_name"))
  
  return(df)
}

## apply ------------------------------------------------------------------ ----

dir_path = "./R"

df = find_function_use_within_functions(dir_path)

# plot prep
plot_df = dplyr::filter(df, open_depth == 1) # optional, helpful
plot_df = dplyr::select(plot_df, function_name, used_function_name)
plot_df = dplyr::filter(plot_df, !is.na(used_function_name))
plot_df = dplyr::distinct(plot_df)

# static network plot
static_df = dplyr::select(plot_df, source = function_name, target = used_function_name)
fn_network = igraph::graph_from_data_frame(d=static_df, directed=TRUE)
plot(fn_network, vertex.size = 8)

# reactive network plot
dynamic_df = dplyr::select(plot_df, from = function_name, to = used_function_name)
networkD3::simpleNetwork(dynamic_df, height="1000px", width="1000px")
# undirected, zooming requires opening in new window
