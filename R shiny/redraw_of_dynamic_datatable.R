###############################################################################
# Redrawing dynamic apps and DT
#
# When we naively redraw a data table with dynamic contents
# (e.g. as per generate_widgets_in_for_loop.R) then the app will fail.
# 
# This is because, outputs (like `output[[this_ui_type]]`) would be defined
# twice (once in each draw of the table).
#
# The key solution for this is to unbind before redrawing.
# This is demonstrated below.
#
# In addition, to prevent memory leaks, it is a good idea to:
# 1) Unbind outputs by assigning as NULL
# 2) Check for existence prior to assignment
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
#
# Reference:
# https://github.com/rstudio/shiny/issues/1989
# https://stackoverflow.com/a/75452634/7742981
# https://stackoverflow.com/a/68560286/7742981
#
###############################################################################



# UI
ui = fluidPage(
  # unbind JS
  tags$head(tags$script(
    HTML(
      "Shiny.addCustomMessageHandler('unbindDT', function(id) {
        var $table = $('#'+id).find('table');
        if($table.length > 0){
          Shiny.unbindAll($table.DataTable().table().node());
        }
      })")
  )),
  actionButton("draw", "Redraw"),
  # uiOutput("ui"),
  DT::dataTableOutput("classify_table")
)

# server
server = function(input, output, session) {
  
  output$ui = renderUI({ p("here") })
  
  output$classify_table <- DT::renderDataTable({
    # unbind at start of redraw
    session$sendCustomMessage("unbindDT", "classify_table")
    
    df = data.frame(
      rows = input$draw,
      UI = as.character(uiOutput("ui")),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(
      df,
      escape = FALSE,
      options = list(
        dom = "t",
        preDrawCallback = DT::JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
        drawCallback = DT::JS('function() { Shiny.bindAll(this.api().table().node()); } ')
      )
    )
  })
}

# run
shinyApp(ui, server)

