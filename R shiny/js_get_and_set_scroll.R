# One of the consequences of storing multiple renderUI components
# within a data table, is that scroll is reset when are rendered
# UI element is interacted with.
#
# The following code fetches and sets the scroll position of a
# wellPanel.
#
# It can be used to reset the scroll position during editting of
# a data table. One possible approach is the redraw the data table
# when the contents change and reset the position of the scroll
# bar using the below method.
#
# References:
# https://stackoverflow.com/questions/4192847/set-scroll-position
# https://stackoverflow.com/questions/41304265/shiny-selectinput-flips-to-the-top-after-display
# https://stackoverflow.com/questions/56211231/r-shiny-reset-vertical-scrollbar-to-top-upon-change-of-inputid
# https://stackoverflow.com/questions/66676159/run-javascript-in-shiny
#


# UI
ui = fluidPage(
  tags$script(
    "Shiny.addCustomMessageHandler('get_pos', function(value) { tPanel4.scrollLeft = value });"
  ),
  tags$script(
    "Shiny.addCustomMessageHandler('set_pos', function(id) {
      Shiny.setInputValue('pos', eval(id).scrollLeft, {priority: 'event'});
    });"
  ),
  
  actionButton("record", "Record"),
  actionButton("replace", "Replace"),
  textOutput("pos"),
  wellPanel(
    id = "tPanel4",
    style = "overflow-y: scroll;",
    DT::dataTableOutput("dt")
  )
)

# server
server = function(input, output, session) {
  session$onSessionEnded(function() { stopApp() })
  
  output$pos = renderText({ input$pos })
  
  observeEvent(input$record, {
    session$sendCustomMessage(type = "set_pos", "tPanel4")
  })
  
  observeEvent(input$replace, {
    session$sendCustomMessage(type = "get_pos", input$pos)
  })
  
  output$dt =  DT::renderDataTable({
    df = as.data.frame(t(as.matrix(1:200)))
    column_names = colnames(df)
    
    dt = DT::datatable(
      data = df,
      colnames = column_names,
      rownames = FALSE,
      selection = "single",
      # class = "compact",
      options = c(
        list(processing = FALSE, dom = "t", ordering = FALSE)
      )
    )
  })
}

# run
print(shinyApp(ui, server, options = list(launch.browser=TRUE)))
