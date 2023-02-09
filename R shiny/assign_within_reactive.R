# Can you assign within a reactive?
#
# Yes. Assignments that occur within a reactive statement
# persist outside the reactive.

library(shiny)

ui = fluidPage(
  textInput("text", "Text goes here", "initial text"),
  textOutput("direct"),
  textOutput("indirect")
)

server = function(input, output, session) {
  rv = reactiveValues(indirect = "none yet")
  
  assignment_reactive = reactive({
    rv$indirect = input$text
    input$text
  })
  
  output$direct = renderText(assignment_reactive())
  
  output$indirect = renderText(rv$indirect)
}


shinyApp(ui = ui, server = server)
