## simple catch of error and warning messages ----------------------------- ----

out = ""

out = tryCatch(
  {
    # see how out changes when commenting the warning and error lines
    stop("error msg")
    warning("warning msg")
    "success"
  },
  error = function(e){ return(e$message) },
  warning = function(w){ return(w$message) }
)

print(out)


## on-mass catch of error and warning messages ---------------------------- ----

# function that returns errors, warnings, and values
test_func = function(ii){
  if(ii %% 3 == 1){ stop(paste0("error", ii)) }
  if(ii %% 3 == 2){ warning(paste0("warning", ii)) }
  return(paste0("success", ii))
}

out = rep(NA, 99)

for(ii in 1:99){
  
  out[ii] = tryCatch(
    {
      test_func(ii)
    },
    error = function(e){ return(e$message) },
    warning = function(w){ return(w$message) }
  )
  
}

print(out)

## multiple warnings >> exits on the first warning ------------------------ ----

out = ""

out = tryCatch(
  {
    warning("warning msg 1")
    print("now msg 2")
    warning("warning msg 2")
    "success"
  },
  warning = function(w){ return(w$message) }
)

print(out)

## error and warning functions can fetch local variables ------------------ ----

out = ""

out = tryCatch(
  {
    for(ii in 1:10){
      if(ii > 5){ stop("too large") }
      # if(ii > 5){ warning("too large") }
    }
    "done"
  },
  error = function(e){ return(paste(e$message, "error as ii =", ii)) },
  warning = function(w){ return(paste(w$message, "warning as ii =", ii)) }
)

print(out)

