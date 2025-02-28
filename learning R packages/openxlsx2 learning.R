## setup ------------------------------------------------------------------ ----

library(openxlsx2)

test_file = "../reference material/openxlsx2 testing.xlsx"

## simplest read and write ------------------------------------------------ ----

# loading without wb_load first
sheet1 = read_xlsx(test_file, sheet = 1, convert = FALSE)

# write without wb_load or wb_save
data(iris)
write_xlsx(iris, test_file)
# HOWEVER this overwrites entire file
# only way to modify workbook is to wb_load and wb_save

## reading ---------------------------------------------------------------- ----
# all of this worked while I had the workbook open

wb = wb_load(test_file)

# list available sheets
openxlsx2::wb_get_sheet_names(wb)

# load to data frame by name
sheet1 = wb_read(wb, "abc")
sheet2 = wb_read(wb, "def")

# load to data frame  by position
sheet1 = wb_read(wb, 1)
sheet2 = wb_read(wb, 2)

# load without type conversion
sheet2 = wb_read(wb, 2, convert = FALSE)

## writing ---------------------------------------------------------------- ----

wb = wb_load(test_file)

data(iris)
iris = head(iris, 10)

# new worksheet
wb = wb_add_worksheet(wb, "new")
wb = wb_set_active_sheet(wb, "new")

# this produces no error message even though the sheet does not exist
wb = wb_set_active_sheet(wb, "new2")
# but this will now error
openxlsx2::wb_get_active_sheet(wb)

# modifying
wb = wb_set_active_sheet(wb, "new")
wb = wb_add_data(wb, "new", x = iris)

wb_read(wb, "new")

# this set all values to NA
wb = wb_clean_sheet(wb, "new")
wb_read(wb, "new")

# unable to save if file open elsewhere
wb_save(wb, test_file)

## key learnings ---------------------------------------------------------- ----
#' 
#' wb created by wb_load is an in-memory representation of the Excel file
#' so it can be read and modified separately from the original file.
#' 
#' If the original file is changed, these changes are not reflected in R
#' until wb_load is called again.
#' Until wb_save is called changes to wb only effect the in-memory version.
#' 
#' Also given the need to pass wb to each of the functions, best to think of
#' a workbook object as similar to a data frame. So wb_* function behave the
#' same way as dplyr functions.
#' 
#' Because wb only exists in local R memory, a conflict only exists between the
#' two when the original file is open and an attempt is made to save the
#' in-memory version.
#' 
