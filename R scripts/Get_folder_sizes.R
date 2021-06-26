# Get directory names, sizes, and last modified
# 2020-05-19
# Simon Anastasiadis

# location to analyse
FOLDER_TO_ANALYSE = "path/goes/here"
# output file name
OUTPUT_FILE_NAME = "directory_size.txt"

# setup
setwd(FOLDER_TO_ANALYSE)
sink(OUTPUT_FILE_NAME)

# outer directory
folder_list = list.dirs(recursive = FALSE)
for(folder in folder_list){

  files = list.files(folder, full.names = TRUE, recursive = FALSE)
  vect_size = sapply(files, file.size)
  size_files = ifelse(length(vect_size) == 0, 0, sum(vect_size))
  last_modified = file.info(folder)$mtime
  
  print(sprintf("8.1f MB | %s | %s | %s", size_files / 1024 / 1024, last_modified, folder, ""))
  
  # inner directory
  inner_folder_list = list_dirs(path = folder, recursive = FALSE)
  for(inner_folder in inner_folder_list){
  
    files = list.files(inner_folder, full.names = TRUE, recursive = TRUE)
	vect_size = sapply(files, file.size)
    size_files = ifelse(length(vect_size) == 0, 0, sum(vect_size))
    last_modified = file.info(folder)$mtime
  
    print(sprintf("8.1f MB | %s | %s | %s", size_files / 1024 / 1024, last_modified, folder, inner_folder))
  }
}

# close file
sink()

# then copy file contents to Excel
# text-to-columns split by "|" and " "
# and analyse
