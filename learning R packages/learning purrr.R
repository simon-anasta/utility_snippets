######### INTO TO PURRR ###############

library(purrr)
library(dplyr)

data(mtcars)

# fit a separate linear model of mpg vs wt for each number of cylinders and return r2 for each
mtcars %>%
  split(.$cyl) %>%
  map(~lm(mpg ~ wt + 1, data = .)) %>%
  map(summary) %>%
  map_dbl("r.squared")

# create every pairwise option
expand.grid(class = 1:4, type = c("A","B"), level = c(0,1,NA))

# nest is like split but it works from group_by
df_of_dfs = mtcars %>%
  group_by(cyl) %>%
  tidyr::nest() %>%
  mutate(lin_mod = map(data, ~lm(mpg ~ wt, data = .))) %>%
  mutate(sumry = map(lin_mod, summary)) %>%
  mutate(rsq = map_dbl(sumry, "r.squared"))

print(df_of_dfs)
# # A tibble: 3 x 5
# # Groups:   cyl [3]
# cyl data               lin_mod sumry        rsq
# <dbl> <list>             <list>  <list>     <dbl>
# 1     6 <tibble [7 x 10]>  <lm>    <smmry.lm> 0.465
# 2     4 <tibble [11 x 10]> <lm>    <smmry.lm> 0.509
# 3     8 <tibble [14 x 10]> <lm>    <smmry.lm> 0.423

############ MAP IS APPLY ##############

addTen = function(v){ return(v + 10) }

my_numbers = c(1, 12, 1000)

## list outputs
#
# via purrr
map(my_numbers, addTen)
# via apply
lapply(my_numbers, addTen)
# approaches are equivalent
all_equal(map(my_numbers, addTen), lapply(my_numbers, addTen))

## vector of doubles output
#
# via purrr
map_dbl(my_numbers, addTen)
# via apply
sapply(my_numbers, addTen)
# approaches are equivalent
all_equal(map_dbl(my_numbers, addTen), sapply(my_numbers, addTen))

# return type matters
all_equal(map_dbl(my_numbers, addTen), lapply(my_numbers, addTen))

# modify matches input type
all_equal(map_dbl(list(1,2,3), addTen), modify(c(1,2,3), addTen))
all_equal(map(list(1,2,3), addTen), modify(list(1,2,3), addTen))
all_equal(map(c(1,2,3), addTen), modify(list(1,2,3), addTen))

########### EXPLORING A DATASET ###################

# An idea very like the following would be part of the explore package

data(starwars)

df = starwars
explored = data.frame(cols = colnames(starwars), stringsAsFactors = FALSE)

explored = explored %>%
  mutate(class = map(df, class)) %>%
  mutate(min = map_if(.x = df, .p = is.numeric, .f = min, na.rm = TRUE, .else = ~{NA}),
         max = map_if(.x = df, .p = is.numeric, .f = max, na.rm = TRUE, .else = ~{NA}),
         mean = map_if(.x = df, .p = is.numeric, .f = mean, na.rm = TRUE, .else = ~{NA})) %>%
  mutate(n_dist = map(df, n_distinct, na.rm = TRUE),
         missings = map(df, ~{sum(is.na(.x))}))

print(explored)
#          cols     class min  max     mean n_dist missings
# 1        name character  NA   NA       NA     87        0
# 2      height   integer  66  264  174.358     46        6
# 3        mass   numeric  15 1358 97.31186     39       28
# 4  hair_color character  NA   NA       NA     13        5
# 5  skin_color character  NA   NA       NA     31        0
# 6   eye_color character  NA   NA       NA     15        0
# 7  birth_year   numeric   8  896 87.56512     37       44
# 8      gender character  NA   NA       NA      5        3
# 9   homeworld character  NA   NA       NA     49       10
# 10    species character  NA   NA       NA     38        5
# 11      films      list  NA   NA       NA     24        0
# 12   vehicles      list  NA   NA       NA     11        0
# 13  starships      list  NA   NA       NA     17        0

# Notes:
# The anonymous function is ~{ ... } with single argument . or .x (equivalent)
# So
# map(my_data, function(col){ sum(is.na(col)) })
# can be shorted to
# map(my_data, ~{ sum(is.na(.)) })
#
# .else (from map_if) must return a function, hence we use ~{NA}
# This is the anonymous function that always returns 'NA'

# discard and keep are the logical filter equivalents to map_if

############# DATAFRAME COLUMNS THAT ARE LISTS #########

list_of_all_films = reduce(starwars$films, c) %>% unique()
list_of_all_vehicles = reduce(starwars$vehicles, c) %>% unique()

df = starwars

map(list_of_all_films, ~{ .x %in% df$films })


# figure out mapping using a single value
x = list_of_all_films[1]

function(x){
  df %>% mutate(!!sym(x) := map_lgl(df$films, function(y){x %in% y})) %>% select(name, !!sym(x))
}

# now nest one map inside the other
#
# note we can not use anonymous functinos here as need to keep names separate
ans = map(.x = list_of_all_films,
          .f = function(x){
            df %>%
              mutate(!!sym(x) := map_lgl(df$films, function(y){ x %in% y})) %>%
              select(name, !!sym(x))
          }) %>%
  reduce(.f = inner_join, by = 'name')

# could have used map2 or pmap instead of nested map, but this approach has better logic:
#
# for each item in list of films
#    create a new column checking is the film-item is in each entry of the films-column
# select character name and logical indicator
# join together all individual tables


# equivalent using has_element, and trusting map_lgl to pass x into has_element as argument .y
ans = map(.x = list_of_all_films,
          .f = function(x){
            df %>%
              mutate(!!sym(x) := map_lgl(df$films, has_element, .y = x)) %>%
              select(name, !!sym(x))
          }) %>%
  reduce(.f = inner_join, by = 'name')
