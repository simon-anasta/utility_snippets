library(shiny)
library(shinyjs)

getWidgetType <- function(widgetId){
  paste0(
    "elem = document.getElementById('", widgetId,"');
    var message;
    if(elem == null){
      message = 'No input with id = ", widgetId," exists.'
    }else{
      // RStudio Viewer + IE workaround (dont have .include())
      if(elem.getAttribute('class').indexOf('js-range-slider') > -1){ 
        message = 'slider'
      }else if (elem.nodeName == 'SELECT'){
        message = 'select'
      }else{
        message = elem.getAttribute('type');
      }
    }
    Shiny.onInputChange('inputType', message)
    "
  )
}

ui <- fluidPage(
  useShinyjs(),
  textInput("textInput", "id = textInput", "text"),
  numericInput("numInput", "id = numInput", 10),
  sliderInput("slideInput", "id = slideInput", 1, 10, 5),
  
  hr(style = "height:1px;border:none;color:#333;background-color:#333;"),
  textInput("widgetType", "widget type by id", "textInput"),
  textOutput("widgetId")
)

server <- function(input, output, session) {
  
  output$widgetId <- renderText({
    runjs(getWidgetType(input$widgetType))
    input$inputType
  })
  
}

shinyApp(ui, server)