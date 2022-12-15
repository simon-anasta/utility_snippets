#
# Simple code check helper
# 2022-12-15
# Simon Anastasiadis
#
# Instructions:
# Press Ctrl + L
# to clear console/display
# Press Ctrl + Shift + F10
# to reset R
# Press Ctrl + Shift + S or click Source
# to run the helper
#

## setup ------------------------------------------------------------

library(rstudioapi)
extensions = c("rds", "RData")

## get directory ----------------------------------------------------

input_dir = selectDirectory(
  caption = "Select Directory to check",
  label = "Select",
  path = getActiveProject()
)

all_files = dir(path = input_dir, recursive = TRUE)
extensions = tolower(extensions)

## support functions ------------------------------------------------

reject_contents = function(file_name){
  print(paste("contents of", file_name, "not recognised format"))
}

extension_to_csv = function(path, insertion = NA){
  new_ext = ifelse(is.na(insertion), ".csv", paste0("_",insertion,".csv"))
  path = gsub("\\.rds$", new_ext, path, ignore.case = TRUE)
  path = gsub("\\.rdata$", new_ext, path, ignore.case = TRUE)
  return(path)
}

write_out_csv = function(contents, path, file, insertion = NA){
  path = file.path(path, file)
  path = extension_to_csv(path, insertion)
  write.csv(contents, file = path, row.names = FALSE)
}

## create output ----------------------------------------------------

for(each_file in all_files){
  this_ext = tools::file_ext(tolower(each_file))
  
  # skip and warn unaccepted file types
  if(! this_ext %in% extensions){
    print(paste("file", each_file, "has been skipped: non-R format"))
    next
  }
  
  file_path = file.path(input_dir, each_file)
  
  ## rds files contain a single data object or a list of objects
  if(this_ext == "rds"){
    contents = readRDS(file_path)
    
    if(!is.data.frame(contents) & !is.list(contents)){ reject_contents(each_file); next }
    
    if(is.data.frame(contents)){ 
      write_out_csv(contents, input_dir, each_file)
    } else if(is.list(contents)) {
      for(name in names(contents)){
        if(!is.data.frame(contents[[name]])){ reject_contents(each_file); next }
        write_out_csv(contents[[name]], input_dir, each_file, name)
      }
    }
    rm("contents")
    
  ## RData files contain unknown contents
  } else if(this_ext == "rdata"){
    tmp = load(file_path)
    for(tt in tmp){
      assignment = paste("contents =", tt)
      eval(parse(text = assignment))
      
      if(!is.data.frame(contents)){ reject_contents(each_file); next }
      
      write_out_csv(contents, input_dir, each_file, tt)
    }
    rm(list = tmp)
  }
}
