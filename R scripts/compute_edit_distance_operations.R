#
# compute edit operations
# 2023-07-12
#
# Reference:
# https://stackoverflow.com/questions/56827772/how-to-know-the-operations-made-to-calculate-the-levenshtein-distance-between-st
#

s1 = "123456789"
s2 = "0123zz67"

out = adist(s1, s2, counts = TRUE)
edit_string = drop(attr(out, "trafos"))

# I = insert
# M = match
# S = substitute
# D = delete

## conversion function ------------------------------------

character_match = function(string, edit_string, match, drop = NA){
  # convert to array
  string = strsplit(string, "")[[1]]
  edit_string = strsplit(edit_string, "")[[1]]
  
  if(!is.na(drop)){
    edit_string = edit_string[edit_string != drop]
  }
  
  if(length(string) != length(edit_string)){
    stop("string and edit_string are different lengths")
  }
  
  output = rep("_", length(edit_string))
  is_match = edit_string == match
  output[is_match] = string[is_match]
  
  output = paste0(output, collapse = "")
  return(output)
}

## interpretation -----------------------------------------

# characters in string 1 that match
character_match(s1, edit_string, "M", "I")
# "123__67__"

# characters in string 1 that were substituted out
character_match(s1, edit_string, "S", "I")
# "___45____"

# characters in string 1 that were deleted
character_match(s1, edit_string, "D", "I")
# "_______89"

# characters in string 2 that match
character_match(s2, edit_string, "M", "D")
# "_123__67"

# characters in string 2 that were substituted out
character_match(s2, edit_string, "S", "D")
# "____zz__"

# characters in string 2 that were inserted
character_match(s2, edit_string, "I", "D")
# "0_______"
