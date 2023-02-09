# Detect interactions with arbitrary shiny widgets
#
# Intended use:
# Allows for observing of dynamic number of widgets.
# Add an observer, and within the observer condition on
# the ID that is returned.
#
# References:
# https://www.r-bloggers.com/2021/01/adding-action-buttons-in-rows-of-dt-data-table-in-r-shiny/
# https://stackoverflow.com/questions/72061061/on-click-for-shiny-inputs-to-get-last-input-clicked-doesnt-work-for-selectinput
# https://stackoverflow.com/questions/75394047/shiny-does-not-detect-shinyinputchanged-event/75395277#75395277
# https://stackoverflow.com/questions/56770222/get-the-event-which-is-fired-in-shiny/56771353#56771353
# https://shiny.rstudio.com/articles/js-events.html

library(shiny)
library(shinyWidgets)

ui <- fluidPage(
  tags$head(
    tags$script(
      "$(document).on('shiny:inputchanged', function(event) {
          if (event.name != 'last_input') {
            Shiny.setInputValue('last_input', event.name);
          }
        });"
    )
  ),
  numericInput("num1", "Numeric", 0),
  textInput("text1", "Text"),
  selectInput("select1", "Select", choices = LETTERS[1:4]),
  selectInput("selectize1", "Selectize", choices = letters[1:4]),
  actionButton("button1", "Button"),
  # however, does not work with shinyWidget::pickerInput
  pickerInput("picker1", "Picker", choices = c(1,2), options = list(title = "This is a placeholder")),
  actionBttn("bttn1", "Bttn", style = "bordered", color = "success"),
  
  textOutput("textout")
)

server <- function(input, output, session) {
  output$textout <- renderText({
    input$last_input
  })
}

shinyApp(ui, server)
