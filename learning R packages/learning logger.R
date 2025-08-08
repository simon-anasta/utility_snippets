# Key functions for logging
# 2025-08-08
#

# References
#
# https://cran.r-project.org/web/packages/logger/vignettes/Intro.html
# https://daroczig.github.io/logger/
# https://daroczig.github.io/logger/articles/anatomy.html
# https://daroczig.github.io/logger/articles/customize_logger.html
# 

library(logger)

# check current logging location
log_appender()

# reset current logging location
log_appender(appender_console)

# appender_tee to send to both console and file
log_appender(appender_tee(file = "C:/NotBackedUp/test_log.txt"))
# appender_file to send log to only console and file
log_appender(appender_file(file = "C:/NotBackedUp/test_log.txt"))

# log some information
log_info("Loading data")
data(mtcars)
log_info("The dataset includes {nrow(mtcars)} rows")
if (max(mtcars$hp) < 1000) {
  log_warn("Oh, no! There are no cars with more than 1K horsepower in the dataset :/")
  log_debug("The most powerful car is {rownames(mtcars)[which.max(mtcars$hp)]} with {max(mtcars$hp)} hp")
}

# check threshold for logging
log_threshold()
# change threshold for logging
log_threshold(TRACE)

# logging levels in order of detail
# OFF, FATAL, ERROR, WARN, SUCCESS, INFO, DEBUG, TRACE

log_threshold(INFO)
log_info("Info message logged")
log_trace("Trace message not logged")
log_threshold(TRACE)
log_trace("Trace message now logged")

# options to log calculations log_eval
g <- mean
x <- 1:31

log_eval(y <- sqrt(g(x)), level = INFO) # assignment must be done with '<-'
log_eval({z = sqrt(g(x))}, level = INFO) # or within {} using =

# value is assigned
str(y)
str(z)

## error and warning handling --------------------------------------------------

# messages, warnings and errors are not logged by default
message("test message")
warning('test warning')
stop('test error')

# we can turn on logger handling of warnings
log_warnings(muffle = TRUE)
warning('test warning')

# we can turn on logger handling of errors
log_errors(muffle = TRUE)
stop('test error')

# the error still causes execution to stop
for(ii in 1:5){
  print(ii)
  stop("here")
}

# it is also possible to handle messages with logger
log_messages()
message("test message")
# this gives two copies of the message - logged and message

# We have not found any way to turn off logging of messages, warnings, or errors
# other than to restart R.

