# Detect a dynamic number of inputs
#
# Slider creates a variable number of buttons.
# Observer is set to detect presses of any button.
# Button pressed is displayed
#
# Alternative - filter on the text of the ID and dispatch to other options

library(shiny)

ui <- fluidPage(
  sliderInput("slider", "Number of buttons", min = 1, max = 5, value = 1),
  uiOutput("button_list"),
  textOutput("button_clicked")
)

# returns a list of all the inputs
access_func = function(input, ids) {
  lapply(ids, function(id){input[[id]]})
}


server <- function(input, output, session) {
  
  rv = reactiveValues(
    num = 1,
    ids = "b1",
    current = 0,
    out = "none yet"
  )
  
  output$button_list = renderUI({
    req(input$slider)
    rv$ids = paste0("b", 1:input$slider)
    rv$current = rep(0, input$slider)
    
    tagList(
      lapply(rv$ids, function(id){
        label = paste("Button", id)
        actionButton(id, label)
      })
    )
  })
  
  observeEvent({access_func(input, rv$ids)},{
    new = unlist(access_func(input, rv$ids), use.names = FALSE)
    req(length(rv$current) == length(new))
    change = which(rv$current != new)[1] # if multiple take the first one
    rv$out = rv$ids[change]
    rv$current = new
  }, ignoreInit = TRUE)
  
  output$button_clicked <- renderText({
    rv$out
  })
}

shinyApp(ui, server)
