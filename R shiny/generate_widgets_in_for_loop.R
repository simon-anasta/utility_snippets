###############################################################################
# Generating output using loop
# 
# Because of lazy evaluation in Shiny, when things are created within a for
# loop we get odd results. For example, instead of each unique item, every item
# gets the same value or id as the last item.
# 
# See for example:
# https://stackoverflow.com/questions/72212625/get-the-value-from-a-loop-in-shiny
#
# One solution is to use `local` to specify that items must be evaluated
# in the immediate context.
#
# References:
# https://stackoverflow.com/a/49910399/7742981
# https://github.com/rstudio/shiny/issues/532
#
# We note one addition to this. Things that exist before iteration may need
# to be excluded from the local.
#
# To demonstrate, contrast the following:
# 1) code run as is
# 2) code run with local commented out (lines 51 & 70)
# 3) code run with df within local (line 51 --> line 41)
#
# 1) gives the expected behaviour, a pair of interacting drop-downs
# 2) instead of two pairs of dropdowns, the drop downs are linked incorrectly
# 3) data table contains no dropdown because uiOutput assignment is only local
###############################################################################

# UI
ui = fluidPage(
  DT::dataTableOutput("classify_table")
)

# server
server = function(input, output, session) {
  # setup
  lookup_ref = data.frame(c1 = c(1,1,1,2,2,2), c2 = c(9,8,7,99,88,77))
  
  # classify table
  output$classify_table <- DT::renderDataTable({
    
    df = data.frame(rows = 1, stringsAsFactors = FALSE)
    for(ii in 1:2){
      
      this_col_name = paste0("dyn_c", ii)
      this_ui_type = paste0("dyn_ui_type_", ii)
      this_ui_aux = paste0("dyn_ui_aux_", ii)
      
      # must be outside local as df already exists
      df[[this_col_name]] = as.character(tagList(
        uiOutput(this_ui_type),
        uiOutput(this_ui_aux)
      ))
      
      local({
        ii = ii
        
        this_ui_type = paste0("dyn_ui_type_", ii)
        this_ui_aux = paste0("dyn_ui_aux_", ii)
        this_select_type = paste0("dyn_select_type_", ii)
        this_select_aux = paste0("dyn_select_aux_", ii)
        
        # drop downs
        output[[this_ui_type]] = renderUI({
          choices = unique(lookup_ref$c1)
          selectizeInput(this_select_type, label = NULL, choices = choices)
        })
        
        output[[this_ui_aux]] = renderUI({
          choices = lookup_ref$c2[lookup_ref$c1 == input[[this_select_type]]]
          selectizeInput(this_select_aux, label = NULL, choices = choices)
        })
        
      }) # end of local
    } # end for loop
    
    DT::datatable(
      df,
      escape = FALSE,
      rownames = FALSE,
      colnames = rep("", ncol(df)),
      class = list(stripe = FALSE),
      selection = "none",
      options = list(
        processing = FALSE,
        dom = "t",
        ordering = FALSE,
        preDrawCallback = DT::JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
        drawCallback = DT::JS('function() { Shiny.bindAll(this.api().table().node()); } ')
      )
    )
  })
  
  
}

# run
shinyApp(ui, server)

###############################################################################
# Additional notes
#
# If we were to redraw the data table above (e.g. add a 'redraw button),
# then the app would fail.
# 
# This is because, outputs (like `output[[this_ui_type]]`) would be defined
# twice (once in each draw of the table).
#
# There are two solutions to this.
# 1) Unbind outputs by assigning as NULL
# 2) Check for existence prior to assignment
#
# In practice, both would be advised to ensure the most robust & stable app.
# Note that (2) by itself is a risk for long running apps where a large number
# of outputs could be created, but then sit idle.
#
# Reference:
# https://github.com/rstudio/shiny/issues/1989
#
# Example of option 1:
# for(ii in 1:2){
#   local({
#     ii = ii
#     output[[paste0("dyn_ui_type_", ii)]] = NULL
#     output[[paste0("dyn_ui_aux_", ii)]] = NULL
#     output[[paste0("dyn_select_type_", ii)]] = NULL
#     output[[paste0("dyn_select_aux_", ii)]] = NULL
#   })
# }
#
# Example of option 2:
# if(this_ui_type %not_in% names(output)){
# output[[this_ui_type]] = renderUI({
#   ref = unique(aRV$lookup_ref$column_type)
#   choices = c("", ref)
#   names(choices) = c("Select column type", ref)
#   selectizeInput(ns(this_select_type), label = NULL, choices = choices, selected = "Unweighted count") 
# })
# }

