# dynamic number of conditions for filter

library(dplyr)
library(rlang)
data(mtcars)

# dynamic generation via a list
output = list(
  c1 = quo(sum(mpg)),
  c2 = quo(n()),
  c3 = quo(n_distinct(mpg))
)

mtcars %>%
  group_by(gear) %>%
  summarise(!!!output)

# dynamic generate in strings
output = c(
  "sum(mpg)",
  "n()",
  "n_distinct(mpg)"
)
output = parse_exprs(output)
names(output) = c("c1","c2","c3")

mtcars %>%
  group_by(gear) %>%
  summarise(!!!output)

# confirm using direct
mtcars %>%
  group_by(gear) %>%
  summarise(
    c1 = sum(mpg),
    c2 = n(),
    c3 = n_distinct(mpg)
  )


