# locate recent files
# 2023-06-30

## user parameters ------------------------------

FOLDER = "input/folder/name/here"
NUM_RECENT_DATES = 10
OUTPUT_FILE = "file_access_records.csv"

## setup ----------------------------------------

library(dplyr)
setwd(FOLDER)

all_files = dir(path = ".", recursive = TRUE, full.names = TRUE)
all_files_info = file.info(all_files)

## focus ----------------------------------------

focus_file_info = all_files_info
focus_file_info$path = rownames(focus_file_info)
focus_file_info$folder = dirname(focus_file_info$path)
focus_file_info$file = basename(focus_file_info$path)

keep_columns = c("path", "folder", "file", "size", "mtime", "ctime", "atime")
focus_file_info = select(focus_file_info, all_of(keep_columns))
rownames(focus_file_info) = NULL

## overview -------------------------------------

ggplot2::ggplot(data = focus_file_info) +
  ggplot2::geom_histogram(ggplot2::aes(x = mtime))

ggplot2::ggplot(data = focus_file_info) +
  ggplot2::geom_histogram(ggplot2::aes(x = ctime))

ggplot2::ggplot(data = focus_file_info) +
  ggplot2::geom_histogram(ggplot2::aes(x = atime))

## latest files & folders -----------------------

latest_accessed = focus_file_info %>%
  mutate(day = as.Date(atime)) %>%
  group_by(day) %>%
  summarise(num = n()) %>%
  arrange(day) %>%
  tail(NUM_RECENT_DATES)

latest_modified = focus_file_info %>%
  mutate(day = as.Date(mtime)) %>%
  group_by(day) %>%
  summarise(num = n()) %>%
  arrange(day) %>%
  tail(NUM_RECENT_DATES)

## display output -------------------------------

# folders
cat("--------------------------------------------------------------\n")
cat("Folders with recent file access\n\n")
focus_file_info %>%
  filter(as.Date(atime) %in% latest_accessed$day) %>%
  pull(folder) %>%
  unique() %>%
  print()

cat("--------------------------------------------------------------\n")
cat("Folders with recent file modified\n\n")
focus_file_info %>%
  filter(as.Date(atime) %in% latest_modified$day) %>%
  pull(folder) %>%
  unique() %>%
  print()

# files
cat("--------------------------------------------------------------\n")
cat("Files with recent access\n\n")
focus_file_info %>%
  filter(as.Date(atime) %in% latest_accessed$day) %>%
  pull(file) %>%
  unique() %>%
  print()

cat("--------------------------------------------------------------\n")
cat("Files with recent modified\n\n")
focus_file_info %>%
  filter(as.Date(atime) %in% latest_modified$day) %>%
  pull(file) %>%
  unique() %>%
  print()

## output ---------------------------------------

write.csv(focus_file_info, OUTPUT_FILE, row.names = FALSE)

