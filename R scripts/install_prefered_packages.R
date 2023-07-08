# Install all preferred packages
#

list_of_packages = c(
  "dplyr",
  "shiny",
  "tidyr",
  "ggplot2",
  "dbplyr",
  "DBI",
  "explore",
  "rlang",
  "purrr",
  "testthat",
  "rmarkdown",
  "glue",
  "devtools",
  "usethis"
)


for(pkg in list_of_packages){
  if(pkg %in% installed.packages()){
    next
  }
  
  install.packages(pkg)
}
