# Logging errors, warnings, and messages
# 2025-08-18
#
# Sink can be an effective way to save progress reporting to a log file.
# However, messages, warnings, and errors are not captured by sink as they
# are displayed by stderr instead of by stdout.

## Function for testing --------------------------------------------------- ----

test_function = function(x){
  print("=================")
  print(x)
  print("ready")
  if(x == "cat") cat("cat output\n")
  if(x == "print") print("print output")
  if(x == "message") message("test message")
  if(x == "warning") warning("test warning")
  if(x == "error") stop("test error")
  
  if(x == "simple try error silent"){
    status = try(stop("simple caught error"), silent = TRUE)
    print(as.character(status))
  }
  
  if(x == "simple try error loud"){
    status = try(stop("simple caught error"), silent = FALSE)
    print(as.character(status))
  }
  
  if(x == "try error"){
    status = tryCatch(
      {stop("caught error")},
      error = function(e){
        msg = paste(e$message, collapse = "\n")
        msg = paste("Stopped with error: ", msg)
        return(msg)
      }
    )
    print(status)
  }
  if(x == "try warning"){
    status = tryCatch(
      {warning("caught warning")},
      warning = function(w){
        msg = paste(w$message, collapse = "\n")
        msg = paste("Stopped with warning: ", msg)
        return(msg)
      }
    )
    print(status)
  }
  print("done")
}

## Global Calling Handlers approach --------------------------------------- ----
#
# One solution is to create a set of globalCallingHandlers that capture stderr
# outputs and reroute them to stdout.
#
# Note that while we implement this using sink, the same ideas apply if using
# writeLines or similar for logging.

#### create global calling handlers ----
#
# These are added to the underlying R handling for messages, warnings, and
# errors. If one of these triggers, then the standard R handling does not
# trigger. If none of these triggers, then the standard R handling triggers.
#
# As there is no way to remove these from an active R session (other than to
# restart the session) we use a global option to control whether these are
# active or not.

create_global_calling_handlers = function(){
  m_func = function(m) {
    if (isTRUE(getOption("myGlobalHandlersEnabled"))) {
      cat("Global message:", conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  }
  
  w_func = function(w) {
    if (isTRUE(getOption("myGlobalHandlersEnabled"))) {
      cat("Global warning:", conditionMessage(w), "\n")
      invokeRestart("muffleWarning")
    }
  }
  
  e_func = function(e) {
    if (isTRUE(getOption("myGlobalHandlersEnabled"))) {
      cat("Global error:", conditionMessage(e), "\n")
    }
  }
  
  globalCallingHandlers(
    message = m_func,
    warning = w_func,
    error = e_func
  )
}

#### Functions for starting and stopping logging ----

start_logging = function(){
  # create global handlers if they do not exists
  if(is.null(getOption("myGlobalHandlersEnabled"))){
    create_global_calling_handlers
  }
  options(myGlobalHandlersEnabled = TRUE)
  sink("./test_sink.txt", split = TRUE)
}

stop_logging = function(){
  sink()
  options(myGlobalHandlersEnabled = FALSE)
}

#### function for execution ----
#
# Execution stops on error, but after error is printed to console and sink-ed
# to file.
#
# This function shows our prefered setup:
# start_logging()
# on.exit(stop_logging(), add = TRUE)


run_function = function(){
  
  start_logging()
  on.exit(stop_logging(), add = TRUE)
  
  test_function("cat")
  test_function("print")
  test_function("message")
  test_function("warning")
  test_function("simple try error silent")
  # test_function("simple try error loud") # interferes with intended logging.
  test_function("try error")
  test_function("try warning")
  test_function("error")
  test_function("cat")
  
}

run_function()

# unlink("./test_sink.txt")

## With Condition Handlers approach --------------------------------------- ----
#
# The global nature of globalCallingHandlers can cause problems. For example it
# interacts with condition handling in the testthat package and devtools::check.
# 
# A more localised solution is withCallingHandlers, which applies to only the
# specified expression.

#### function for execution ----
#
# Execution stops on error. , but after error is printed to console and sink-ed
# to file.

run_function = function(){
  
  sink("./test_sink.txt", split = TRUE)
  on.exit(sink(), add = TRUE)
  
  test_function("cat")
  test_function("print")
  test_function("message")
  test_function("warning")
  # test_function("simple try error silent")
  # test_function("simple try error loud") # interferes with intended logging.
  test_function("try error")
  test_function("try warning")
  test_function("error")
  test_function("cat")
  
}

#### execution ----

withCallingHandlers(
  {
    run_function()
  },
  message = function(m) {
    cat("Global message:", conditionMessage(m))
    invokeRestart("muffleMessage")
  },
  
  warning = function(w) {
    cat("Global warning:", conditionMessage(w), "\n")
    invokeRestart("muffleWarning")
  },
  
  error = function(e) {
    cat("Global error:", conditionMessage(e), "\n")
  }
)

print("done")

# unlink("./test_sink.txt")
