#####################################################################################################
#' Description: Demonstrate more compact code
#' Author: Simon Anastasiadis
#' 
#' Dependencies: dbplyr_helper_functions.R, utility_functions.R, table_consistency_checks.R,
#' overview_dataset.R, summary_confidential.R
#' 
#' History (reverse order):
#' 2022-05-16 SA v1
#####################################################################################################
## parameters -------------------------------------------------------------------------------------

# locations
ABSOLUTE_PATH_TO_TOOL <- "~/Network-Shares/...tools"
ABSOLUTE_PATH_TO_ANALYSIS <- "~/Network-Shares/.../analysis"

# inputs
DATABASE = "[database_name]"
OUR_SCHEMA = "[schema_name]"
INPUT_TABLE = "[table_name]"

## setup ------------------------------------------------------------------------------------------

setwd(ABSOLUTE_PATH_TO_TOOL)
source("utility_functions.R")
source("dbplyr_helper_functions.R")
source("table_consistency_checks.R")
source("overview_dataset.R")
source("summary_confidential.R")
setwd(ABSOLUTE_PATH_TO_ANALYSIS)

## access dataset ---------------------------------------------------------------------------------
db_con = create_database_connection(database = "database_name")
working_table = create_access_point(db_con, DATABASE, OUR_SCHEMA, INPUT_TABLE)

## version 1 - high repetition --------------------------------------------------------------------
#
# High repetition
# Hard to review
#

v1 = working_table %>%
  mutate(
    msd_repaid_2012 = ifelse(msd_repaid_2012 < 0, -1.0 * msd_repaid_2012, 0),
    msd_repaid_2013 = ifelse(msd_repaid_2013 < 0, -1.0 * msd_repaid_2013, 0),
    msd_repaid_2014 = ifelse(msd_repaid_2014 < 0, -1.0 * msd_repaid_2014, 0),
    msd_repaid_2015 = ifelse(msd_repaid_2015 < 0, -1.0 * msd_repaid_2015, 0),
    msd_repaid_2016 = ifelse(msd_repaid_2016 < 0, -1.0 * msd_repaid_2016, 0),
    msd_repaid_2017 = ifelse(msd_repaid_2017 < 0, -1.0 * msd_repaid_2017, 0),
    msd_repaid_2018 = ifelse(msd_repaid_2018 < 0, -1.0 * msd_repaid_2018, 0),
    msd_repaid_2019 = ifelse(msd_repaid_2019 < 0, -1.0 * msd_repaid_2019, 0),
    msd_repaid_2020 = ifelse(msd_repaid_2020 < 0, -1.0 * msd_repaid_2020, 0),
  
    moj_repaid_2012 = ifelse(moj_repaid_2012 < 0, -1.0 * moj_repaid_2012, 0),
    moj_repaid_2013 = ifelse(moj_repaid_2013 < 0, -1.0 * moj_repaid_2013, 0),
    moj_repaid_2014 = ifelse(moj_repaid_2014 < 0, -1.0 * moj_repaid_2014, 0),
    moj_repaid_2015 = ifelse(moj_repaid_2015 < 0, -1.0 * moj_repaid_2015, 0),
    moj_repaid_2016 = ifelse(moj_repaid_2016 < 0, -1.0 * moj_repaid_2016, 0),
    moj_repaid_2017 = ifelse(moj_repaid_2017 < 0, -1.0 * moj_repaid_2017, 0),
    moj_repaid_2018 = ifelse(moj_repaid_2018 < 0, -1.0 * moj_repaid_2018, 0),
    moj_repaid_2019 = ifelse(moj_repaid_2019 < 0, -1.0 * moj_repaid_2019, 0),
    moj_repaid_2020 = ifelse(moj_repaid_2020 < 0, -1.0 * moj_repaid_2020, 0),
    
    ird_repaid_2012 = ifelse(ird_repaid_2012 < 0, -1.0 * ird_repaid_2012, 0),
    ird_repaid_2013 = ifelse(ird_repaid_2013 < 0, -1.0 * ird_repaid_2013, 0),
    ird_repaid_2014 = ifelse(ird_repaid_2014 < 0, -1.0 * ird_repaid_2014, 0),
    ird_repaid_2015 = ifelse(ird_repaid_2015 < 0, -1.0 * ird_repaid_2015, 0),
    ird_repaid_2016 = ifelse(ird_repaid_2016 < 0, -1.0 * ird_repaid_2016, 0),
    ird_repaid_2017 = ifelse(ird_repaid_2017 < 0, -1.0 * ird_repaid_2017, 0),
    ird_repaid_2018 = ifelse(ird_repaid_2018 < 0, -1.0 * ird_repaid_2018, 0),
    ird_repaid_2019 = ifelse(ird_repaid_2019 < 0, -1.0 * ird_repaid_2019, 0),
    ird_repaid_2020 = ifelse(ird_repaid_2020 < 0, -1.0 * ird_repaid_2020, 0)
  )

## version 2 - variables to list ------------------------------------------------------------------
#
# No repetition of commands
# Easy to edit input list
# Formula / calculation appears only once
# Much easier to check
#
# But repetition in variable names
# Hard to check input list
#

repaid_cols = c(
  "msd_repaid_2012",
  "msd_repaid_2013",
  "msd_repaid_2014",
  "msd_repaid_2015",
  "msd_repaid_2016",
  "msd_repaid_2017",
  "msd_repaid_2018",
  "msd_repaid_2019",
  "msd_repaid_2020",
  
  "moj_repaid_2012",
  "moj_repaid_2013",
  "moj_repaid_2014",
  "moj_repaid_2015",
  "moj_repaid_2016",
  "moj_repaid_2017",
  "moj_repaid_2018",
  "moj_repaid_2019",
  "moj_repaid_2020",
  
  "ird_repaid_2012",
  "ird_repaid_2013",
  "ird_repaid_2014",
  "ird_repaid_2015",
  "ird_repaid_2016",
  "ird_repaid_2017",
  "ird_repaid_2018",
  "ird_repaid_2019",
  "ird_repaid_2020"
)

# formulas
mutate_formula = glue::glue("ifelse({repaid_cols} < 0, -1.0 * {repaid_cols}, 0)")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = repaid_cols

v2 = working_table %>%
  mutate(!!! mutate_list)

## version 3 - auto-generate list -----------------------------------------------------------------
#
# No repetition of commands or input list
# Formula / calculation appears only once
# Much easier to check
#
# But complexity in making input list
# Hard to edit input list
#

# make list of columns
prefix = c("msd", "moj", "ird")
years = 2000 + 12:20

df = purrr::cross_df(list(prefix = prefix, years = years))
repaid_cols = glue::glue("{df$prefix}_repaid_{df$years}")

# formulas
mutate_formula = glue::glue("ifelse({repaid_cols} < 0, -1.0 * {repaid_cols}, 0)")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = repaid_cols

v3 = working_table %>%
  mutate(!!! mutate_list)

## output scripts ---------------------------------------------------------------------------------

sink("../documentation/compact_code_versions.sql")
print("/* version 1 - high repetition */")
print(show_query(v1))
print("/* version 2 - variables to list */")
print(show_query(v2))
print("/* version 3 - auto-generate list */")
print(show_query(v3))
sink()

## close connection -------------------------------------------------------------------------------
close_database_connection(db_con)
