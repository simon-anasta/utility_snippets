# Search R, SAS, and SQL fiels in a directory for specified text
# Simon Anastasiadis

# location to analyse
FOLDER_TO_ANALYSE = "/path/goes/here"
# output file name
OUTPUT_FILE_NAME = "checked"
# your output will be saved one folder up from the folder to analyse

# Preset search patterns
# Uncomment the desired text to search
#
# KEYWORD = "IDI_Clean_" # fines all refreshes
# KEYWORD = "[0123456789]" # fineds all numbers
# KEYWORD = "MAA20[0-9][0-9]-[0-9][0-9]" # finds all schemas in the form MAA20XX-YY
# KEYWORD = "TOP " # For checking if any SQL scripts contain the TOP keyword

# setup
setwd(FOLDER_TO_ANALYSE)
output_df = data.frame(stringsAsFactors = FALSE)
options(warn = -1)

for(each_file in dir(recursie = TRUE)){
  # if file has an R, SQL or SAS extension
  if(grepl("\\.R$", each_file) || grepl("\\.sql$", each_file) || grepl("\\.sas$", each_file)){
    # setup
	line_number = 0
	out_lines = 0
	this_file_df = data.frame(stringsAsFactors = FALSE)
	
	# read file
	con = file(each_file, "r")
	while( TRUE ){
	  line_number = line_number + 1
	  line = readLines(con, n = 1)
	  # stop at end of document
	  if(length(line) == 0){
	    break
	  }
	  # record lines with matching keywords
	  if(grepl(KEYWORD, line)){
	    out_lines = out_lines + 1
		this_file_df = rbind(this_file_df,
		                     as.data.frame(list(msg = "match",
							                    file = each_file,
												line = line_number,
												contents = line)))
	  }
	}
	# done reading file
	close(con)
    # record file to output df
    output_df = rbind(output_df,
                      as.data.frame(list(msg = "file checked",
                                         file = each_file,
                                         line = 0,
                                         contents = paste(out_lines, "lines found with matches of", line_number, "lines read"))),
                      this_file_df)
  }
}

options(warn = 0)  
file_name = paste0("../", OUTPUT_FILE_NAME, as.character(Sys.time()), ".csv")
file_name = gsub(":", "_", file_name)
write.csv(output_df, file_name, row.names = FALSE)
