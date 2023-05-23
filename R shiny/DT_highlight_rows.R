# Approach to highlighting rows
# using DT::datatable
#
# Conclusion:
# It works for many applications, but setting colour formatting via
# DT::formatStyle also clashes with some of the other settings we
# want to apply to the table.
#
# As we can use HTML within DT::datatable by setting escape = FALSE
# this may be a more powerful option for applying row or cell formatting.
# 

data(mtcars)
df = mtcars

label = 1:nrow(df)
df = as.data.frame(df)
rownames(df) = label

background_colour = dplyr::case_when(
  label <= 4 ~ "#CCCCCC",
  label <= 6 ~ "#DDDDDD",
  TRUE ~ ""
)

# row names are required
# style defermined by (label, background_colour) pairs
# - label must link to rownames
# - background_colour must contain RGB strings

dt = DT::datatable(
  data = df,
  colnames = c("m", "c","d","h","d","w","q","v","a","g","c"),
  # rownames = FALSE,
  selection = "single",
  class = "compact",
  options = c(
    list(processing = FALSE, dom = "t", ordering = FALSE),
    # autoWidth = TRUE,
    pageLength = 11
  )
)

# can not use
# - autoWidth : it prevents alignment of column names and contents
# - rownames : it prevent background colour of rows

DT::formatStyle(
  dt,
  0,
  target = "row",
  backgroundColor = DT::styleEqual(label, background_colour)
)
