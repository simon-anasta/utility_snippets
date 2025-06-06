# readLines enforcing a requirement for UTF-8 encoding
# 
# R assumes UTF-8 encoding by default. Errors are common when working with files
# that contain characters that are not UTF-8. However, the error can arise long
# after files are loaded into R, making it harder to track down the cause.
# 
# Detecting lack of UTF-8 when reading file into R means concerns are caught
# earlier. Often the best solution is for users to edit the files.
# 
readLines_utf8 = function(file_name_and_path){
  stopifnot(file.exists(file_name_and_path))
  
  # create connection with enforced encoding
  filecon = file(file_name_and_path, "rt", encoding = "UTF-8")
  
  output = tryCatch(
    {
      readLines(con = filecon)
    },
    warning = function(w){
      # 'invalid input' implies not UTF-8 format
      if(grepl("invalid input", w, fixed = TRUE)){
        close(filecon)
        warning(w)
        msg = c(
          
        )
        stop(paste(msg, collapse = "\n"))
      }
      warning(w)
    }
  )
  close(filecon)
  return(output)
}
