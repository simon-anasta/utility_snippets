#' Minimal reproducible example
#' 
library(shiny)

## Define UI --------------------------------------------
ui <- fluidPage(
  actionButton("all_button", "All"),
  actionButton("none_button", "None"),

  checkboxGroupInput("A_checkbox", label = "A", choices = c('a','b','c')),
  checkboxGroupInput("Z_checkbox", label = "Z", choices = c('x','y','z'))
)

## Define server logic --------------------------------------------
server <- function(input, output, server, session) {
  
  observeEvent(input$all_button,{
    updateCheckboxGroupInput(session, "A_checkbox", selected = c('a','b','c'))
    updateCheckboxGroupInput(session, "Z_checkbox", selected = c('x','y','z'))
  })

  observeEvent(input$none_button,{
    updateCheckboxGroupInput(session, "A_checkbox", selected = character(0))
    updateCheckboxGroupInput(session, "Z_checkbox", selected = character(0))
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)