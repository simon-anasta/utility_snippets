
## setup -------------------------------------------------------- ----

setwd("~/Network-Shares/DataLabNas/MAA")

projects = c(
  "MAA2017-60 Education system performance for preschool and schoolage children",
  "MAA2019-92",
  "MAA2020-37",
  "MAA2020-47",
  "MAA2021-60",
  "MAA2023-28",
  "MAA2016-23 CWM"
  # 
  # 
  # "MAA2023-55",
  # "MAA2023-46",
  # "MAA2023-44",
  # "MAA2020-61"
)

output_file = "/nas/DataLab/MAA/MAA2023-46/social investment FVSV/Resources/file_list.csv"

## get info from every project ---------------------------------- ----

all_project_info = list()

for(pp in projects){
  path = fs::path(".", pp)
  
  all_files = fs::dir_ls(path = path, recurse = TRUE)
  all_files = fs::path_real(all_files)
  
  all_file_info = fs::file_info(all_files)
  all_file_info$project = pp
  all_file_info$ext = fs::path_ext(all_file_info$path)
  
  all_project_info = c(all_project_info, list(all_file_info))
}

## clean -------------------------------------------------------- ----

all_project_info = dplyr::bind_rows(all_project_info)

all_project_info = dplyr::filter(
  all_project_info,
  ext == "sql",
  substr(user, 1, 3) == "dl_"
)

write.csv(all_project_info, output_file, row.names = FALSE)
