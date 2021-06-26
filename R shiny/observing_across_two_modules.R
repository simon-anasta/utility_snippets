library(shiny)

moduleUI <- function(id) {
  ns <- NS(id)
  uiOutput(ns("my_link"))
}

module <- function(input, output, session, number, parent) {
  output$my_link <- renderUI({ 
    actionLink(session$ns("link"), paste0("This is a link to ", number))
  })
  
  observeEvent(input$link,{
    updateSelectInput(session = parent,"selectInput",selected=number)  # now works
  })
}

ui <-  fluidPage(
    selectInput("selectInput","Choose one option",choices=seq(1,10),selected=1),
    moduleUI("5"),
    moduleUI("10")
)

server <- function(session,input, output) {
  callModule(module = module, id = "5", 5, parent = session)
  callModule(module = module, id = "10", 10, parent = session)
}

shinyApp(ui = ui, server = server)