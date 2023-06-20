library(shiny)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  hr(),
  p("Button to hide"),
  actionButton('s1','S1'),
  actionButton('submit','SUBMIT'),
  actionButton('s2','S2'),
  hr(),
  actionButton("hide", "Hide")
)

server <- function(input, output, session) {
  
  observeEvent(input$hide, {
    if(input$hide %% 2 == 0){
      shinyjs::show("submit")
    } else {
      shinyjs::hide("submit")
    }
  })
}

print(shinyApp(ui, server))
