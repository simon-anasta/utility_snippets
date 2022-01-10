###############################################################################
#' Worksheet of basic R building blocks
#' Simon Anastasiadis
#' 2021-12-23
#' 
#' This sheet provides a series of short exercises/examples to help build
#' familiarity and experience with R.
###############################################################################

## working directory ----------------------------------------------------------

# get the current working directory using code
getwd()

# open a folder in Windows and change the working directory to this folder
# note the different slashes "\" vs "/"
setwd("C:/Documents and Settings/")
setwd("C:\\Documents and Settings\\")
# setwd("C:\Documents and Settings\") # errors

# go to the working directory using the file pane
# Files --> More --> Go To Working Directory

# set the working directory using the file pane
# Files --> navigate to desired folder --> More --> Set As Working Directory

## comments and headers -------------------------------------------------------

# use # to start a comment, code that is commented is not run
# this_code = "will not be run"

# use # to add a comment to the end of a line
favourite_number = 13 # so I don't forget my favourite number

# use (at least) two # and (at least) four - to create a title

## title --------
# ctrl + O = collapse all
# ctrl + shift + O = uncollapse all

# notice how RStudio inserts arrows beside a title to collapse the section
# try the keyboard shortcuts to collapse and expand all title areas

## assignment -----------------------------------------------------------------

# store a value in a variable using =
my_value = 1
# store a value in a variable using <-
my_value <- 1
# observe your variables appear in the Environment pane

# try to assign a variable that starts with a number
# 1var = 1 # errors
# try to assign a variable with a special character in the name
# my@var = 1 # errors
# try to assign a variable that contains a space in the name
# my var = 1 # errors

# use back tick ` (same button as ~) for variables names that are unusua;
`1var` = 1
`my@var` = 1
`my var` = 1

## variable types -------------------------------------------------------------

# variables in R can be of different types, class() tells you the type
class("hello")
class(2)
class(TRUE)

# you can check types with is.* functions
is.character("hello")
is.character(3)
is.numeric(123)
# you can convert types with as.* functions
as.character(4)
as.numeric("100")

# non-values have their own checks
# NA = Not Available, e.g. as.numeric("apple")
# NaN = Not a Number, e.g. 0 / 0
# Inf = Infinity, e.g. 1 / 0
is.na(2)
is.na(NA)
is.nan(NA)
is.nan(NaN)

## strings --------------------------------------------------------------------

# use single quotes to create a string
'hello world'
# use double quotes to create a string
"hello world"

# store your string in a variable
my_string = "hello world"
# print() and cat() your variable and observe the difference
print(my_string)
cat(my_string)

# insert a new-line character into a string "\n"
my_string = "hello\nworld"
# print() and cat() this string and notice the difference
print(my_string)
cat(my_string)

# write a string that contains double quotes " inside it
my_string = 'double"quotes'
my_string = "double\"quotes"
# write a string that contains single quotes ' inside it
my_string = "single'quotes"
# print() both strings and notice how R handles them differently
print(my_string)

## manipulating strings -------------------------------------------------------

# use paste() and paste0() to connect two strings together
paste("hello", "world")
paste0("hello", "world")

# try passing several vectors to paste()
v1 = c("hello", "hello")
v2 = c("Alice", "Bob")
paste(v1, v2)

# try passing vectors of different lengths to paste()
v1 = "hello"
v2 = c("Alice", "Bob")
paste(v1, v2)
# can you get an error or warning by changing the length?

# try passing a vector to paste() with the collapse argument
paste(c("hello", "world"), collapse = "_")

## read and write text to files -----------------------------------------------

# use dir() to list files in the current directory
dir()

# use . to refer to the same folder
file_name = "./my file.txt"
# use .. to refer to the containing folder (one-up)
file_name = "../my file.txt"

# write "hello world" to file
my_file = file(file_name)
writeLines("hello world", my_file)
close(my_file)

# check file exists and contains correct contents
# try using . and ..

# read from file
my_file = file(file_name)
readLines(my_file)
close(my_file)

## read and write tables with csv files ---------------------------------------

# read csv file
my_dataframe = read.csv("path/folder/file.csv")

# write csv
write.csv(my_dataframe, "path/folder/file.csv", sep = ",")

## packages -------------------------------------------------------------------

# check if the dplyr package exists
"dplyr" %in% installed.packages()

# install the dplyr package
install.packages("dplyr")
# we also recommend the glue, shiny, and explore packages

# load a package into R memory
library(dplyr)

# use a function from a package without loading it into memory
glue::glue("text")

## consult documentation ------------------------------------------------------

# use ? before a function/command to see information about it in the Help panel
?paste

# use ?? to search for commands that contain the text
??glue

# use the internet to search for examples

## functions ------------------------------------------------------------------

# any command following by brackets is a function
getwd()
# some functions have arguments (things that must git within the brackets)
setwd("C:/Documents and Settings")
# functions can have many arguments, arguments are separated by a comma
paste("a", "b", "c", "d")
# some arguments are named
paste("a", "b", "c", "d", sep = "_")
# some arguments have default values
# ?paste shows that by default sep = " "

# R matches arguments first by name, then by order
# ... arguments can take any number of inputs

# you can make your own functions
simple_add = function(a,b){
  return(a+b)
}
# function is the command to create a function
# the {} contains all the code that is part of the function
# a and b are the inputs to the function
# return tells the function what to give back once it is done

# call the function
simple_add(1,2)

# if you are going to duplicate code many times, with small variations
# the making a function may be a good idea, the variations become your inputs
output = paste("hello","1","there","1","world","1")
output = paste("hello","2","there","2","world","2")
output = paste("hello","3","there","3","world","3")

hello_there_world = function(num){
  num = as.character(num)
  return(paste("hello",num,"there",num,"world",num))
}

output = hello_there_world(1)
output = hello_there_world(2)
output = hello_there_world(3)

## data frames ----------------------------------------------------------------

# R contains several build in datasets, list all datasets
data()
# load an existing dataset using its name
data(mtars)
# starwars, mtcars, iris are three commonly used examples

# get column names
colnames(mtcars)
# get first few rows
head(mtcars)

# get only a single column
mtcars$mpg
mtcars[,1]
mtcars[["mpg"]]

## pipe -----------------------------------------------------------------------

# pipe makes LHS the first argument of RHS
"a" %>% paste("b") == paste("a", "b")

# makes for more readible code

# these are equivalent
# 1
answer = paste("a", "b")
answer = paste(answer, "c")
answer = paste(answer, "d")
# 2
answer = paste(paste(paste("a", "b"), "c"), "d")
# 3
answer = "a" %>%
  paste("b") %>%
  paste("c") %>%
  paste("d")

# these are equivalent
# 1
answer = mutate(my_dataframe, new_col = 2*old_col)
answer = group_by(answer, new_col)
answer = summarise(answer, num = n())
# 2
answer = summarise(group_by(mutate(my_dataframe, new_col = 2*old_col), new_col), num = n())
# 3
answer = my_dataframe %>%
  mutate(new_col = 2*old_col) %>%
  group_by(new_col) %>%
  summarise(num = n())

# which approach is easier to read?

## dplyr functions ------------------------------------------------------------

data(mtcars)

# keep only certain columns
mtcars %>% select(mpg, cyl)
# keep only certain columns & rename them
mtcars %>% select(new_name = mpg, new_name2 = cyl)

# keep all columns renaming only the listed ones
mtcars %>% rename(new_name = mpg)

# keep only certain rows
mtcars %>% filter(gear == 4)

# discard duplicates
mtcars %>% distinct()

# create new columns from old
mtcars %>% mutate(double_gear = gear*2)
mtcars %>% mutate(large_gear = ifelse(gear >= 4, "y", "n"))
# create new columns from old, overwriting the old
mtcars %>% mutate(gear = 2*gear)

# summarise results
mtcars %>%
  group_by(am, gear) %>% # one output row for each unique combination
  summarise(num = n(), # count rows
            sum_mpg = sum(mpg), # sum a column
            avg_cyl = mean(cyl)) # mean a column

## if conditions --------------------------------------------------------------

# simple inline checks
result = ifelse(condition, "yes", "no")
result = if_else(condition, "yes", "no")
# compare difference
?ifelse
?if_else
# example
value = 4
input_value_was_four = ifelse(value == 4, "yes", "no")
value = 3
input_value_was_four = ifelse(value == 4, "yes", "no")

# run code only if condition is true
input_value = 10
if(is.numeric(input_value)){
  print("numeric input")
  output_value = input_value + 1
}
input_value = "a"
if(is.numeric(input_value)){
  print("numeric input")
  output_value = input_value + 1
}

# run code if condition is true, other code if condition is false
input_value = "a"
if(is.numeric(input_value)){
  print("numeric input")
  output_value = input_value + 1
} else {
  print("not numeric")
}

#  stack multiple conditions together
input = 16
if(input %% 2 == 0){
  print("divisible by 2")
} else if(input %% 4 == 0){
  print("divisible by 4")
} else if(input %% 8 == 0){
  print("divisible by 8")
} else {
  print("not even")
}
# fix this code so input = 16 gives output of "divisible by 8"

## vectors --------------------------------------------------------------------

# store multiple values in a single variable
my_numbers = c(1,2,3)
# careful when values are of different types
c(1, "a")
# first 100 digits
first_100 = 1:100

# fetch first value
first_100[1]
# fetch 6th and 11th positions
first_100[c(6,11)]

# fetch all but first value
first_100[-1]

# combine values
my_numbers = c(1,2,3)
my_numbers = c(my_numbers, 4)


# lists are not vectors
# common source of confusion
my_list = list(1,2,3)
class(my_list)
class(my_numbers)

# accessing lists with [] produces sublists
my_sublist = my_list[1]
class(my_sublist)

# accessing lists with [[]] produces values
my_value = my_list[[1]]
class(my_value)

## for loops ------------------------------------------------------------------

# Do a task once for each item in a vector
for(ii in 1:5){
  msg = paste("iteration", ii)
  print(msg)
}

# Do a task using each component of a list
for(value in list("a",1,NA, c(1,2,3))){
  print("this item:")
  print(value)
}

# Loop through a vector changing its values
my_vector = 1:100
for(ii in 1:length(my_vector)){
  my_vector[ii] = my_vector[100 - ii]
}

# Loop through all pairs of a vector
my_vector = 1:5
for(ii in 1:4){
  for(jj in 2:5){
    print(paste("(",ii,",",jj,")"))
  }
}

# force early exit from a for loop
for(ii in 1:1000000000){
  print(ii)
  if(ii == 4){
    break
  }
}

# skip to the next iteration of the for loop
for(ii in 1:5){
  print("s")
  if(ii == 2){
    next
  }
  print(ii)
}
