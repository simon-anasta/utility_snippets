###############################################################################
# Version 1
# Buttons
#
# Reference:
# https://stackoverflow.com/questions/55034483/shiny-widgets-in-dt-table
#
# Notes:
# 
# Buttons are made as text.
#
# Two non-DT buttons are made, one using `actionButton` and the other using
# text inside `HTML`. Both function as expected. These appear to be bound to
# shiny automatically.
#
# Two DT buttons are made using text. These are not bound automatically to
# shiny. The preDrawCallback and drawCallback take care of the binding of
# these buttons to shiny.
#
# If you inspect the webpage generated by this output you will observe that
# the buttons also include as part of their class "shiny-bound-input". This
# is part of how R knows which components of the webpage it needs to monitor
# and update and which parts are not.
# 
# Adding this text to a button object is not sufficient to bind a button to
# shiny. Better to consider this text an indication that an object has been
# through some form of binding process.
#
# Binding appears to be driven by context. Calling `actionButton` from the
# console does not produce a bound input. But when it is called as part of an
# app then the binding is created.
#
# This context detection does not appear to work when the button is created
# within a DT data table. Hence the need to explcitly bind the widget.
###############################################################################

library(shiny)

make_button = function(id, label){
  paste0('<button id="', id, '" type="button" class="btn btn-default action-button">', label, '</button>')
}


ui <- fluidPage(
  HTML(make_button("id1", "label1")),
  actionButton("id2", "label2"),
  hr(),
  DT::dataTableOutput("dt"),
  hr(),
  textOutput("out1"),
  textOutput("out2"),
  textOutput("out3"),
  textOutput("out4")
)


# Define the server code
server <- function(input, output) {
  output$out1 = renderText({ input$id1 })
  output$out2 = renderText({ input$id2 })
  output$out3 = renderText({ input$id3 })
  output$out4 = renderText({ input$id4 })
  
  output$dt = DT::renderDataTable({
    data.frame(
      code = c("a", "b"),
      button = c(make_button("id3", "label3"), make_button("id4", "label4"))
    )
  },
  selection = "none",
  escape = FALSE,
  rownames = FALSE, 
  options = 
    list(
      preDrawCallback = DT::JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
      drawCallback = DT::JS('function() { Shiny.bindAll(this.api().table().node()); } ')
    )
  )
  
}

# Return a Shiny app object
app1 = shinyApp(ui = ui, server = server)
#print(app1)

###############################################################################
# Version 2
# SelectInput and UI output
#
# Notes:
#
# We do not have to generate the widgets within DT using a special function.
# It is sufficient to generate them and convert them to character.
#
# Binding DT widgets to shiny also connects to output. In version 1 we only
# has shiny inputs within the DT data table. But in version 2 we ave both
# an input n an output.
###############################################################################

library(shiny)

ui <- fluidPage(
  DT::dataTableOutput("dt"),
  textOutput("out1"),
  textOutput("out2")
)


# Define the server code
server <- function(input, output) {
  
  output$dt = DT::renderDataTable({
    data.frame(
      selector = as.character(selectInput("id1", NULL, c("A", "B"))),
      aux = as.character(uiOutput("id2"))
    )
  },
  selection = "none",
  escape = FALSE,
  rownames = FALSE, 
  options = 
    list(
      preDrawCallback = DT::JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
      drawCallback = DT::JS('function() { Shiny.bindAll(this.api().table().node()); } ')
    )
  )
  
  output$id2 = renderUI({
    choices = paste0(input$id1, 1:4)
    selectInput("id3", NULL, choices)
  })
  
  output$out1 = renderText({ input$id1 })
  output$out2 = renderText({ input$id3 })
}

# Return a Shiny app object
app2 = shinyApp(ui = ui, server = server)
print(app2)
