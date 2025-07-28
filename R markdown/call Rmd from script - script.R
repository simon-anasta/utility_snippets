# run_reports.R

library(rmarkdown)

# Define a list of parameter sets
params_list = list(
  list(name = "setosa", colour = "red"),
  list(name = "versicolor", colour = "darkgreen"),
  list(name = "virginica", colour = "blue")
  
)

# Loop through each set and render the Rmd
for (params in params_list) {
  rmarkdown::render(
    input = "./callable Rmd by script.Rmd",
    params = params,
    output_file = paste0("report ", params$name, ".html"),
    quiet = TRUE
  )
}
