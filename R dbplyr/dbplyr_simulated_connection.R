library(dbplyr)
library(dplyr)

data(starwars)

# pick your simulated connection type (there are many options, not just what I have shown here)
remote_df = tbl_lazy(starwars, con = simulate_mssql())
remote_df = tbl_lazy(starwars, con = simulate_mysql())
remote_df = tbl_lazy(starwars, con = simulate_postgres())

# not all translations are defined
remote_df %>%
  mutate(substring_col = str_extract(name, "Luke")) %>%
  show_query()
# Error:str_extract() is not available in the SQL variant

# alternatives can be found
remote_df %>%
  mutate(substring_col = grepl("Luke", name)) %>%
  show_query()
