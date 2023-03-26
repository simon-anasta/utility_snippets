# dynamic number of conditions for filter

library(dplyr)
library(rlang)
data(mtcars)


ccond = quos(gear == 4, wt > 3)

mtcars %>%
  dplyr::filter(!!!ccond)

# also works with dbplyr

library(dbplyr)

mtcars_postgres = dbplyr::tbl_lazy(mtcars, con = dbplyr::simulate_postgres())

mtcars_postgres %>%
  dplyr::filter(`!!!`(ccond))


