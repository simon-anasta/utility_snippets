#
# When creating UI within the server via renderUI and uiOutput
# there is no name space existing by default.
#
# Hence ns = NS(id) is not sufficient.
# instead we use ns = session$ns
#
# Reference:
# https://shiny.posit.co/r/articles/improve/modules/
# https://stackoverflow.com/questions/72035607/renderui-in-a-modal-inside-nested-shiny-modules
#


library(shiny)

## inner ----
inner_module_UI = function(id){
  ns = shiny::NS(id)
  shiny::uiOutput(ns("radio"))
}

inner_module_Server = function(id){
  shiny::moduleServer(id, function(input, output, session){
    ns = session$ns
    
    output$radio = renderUI({
      radioButtons(inputId = ns("rd"), label = NULL, choices = 1:3)
    })
    
    observeEvent(input$rd, { print(input$rd) }, ignoreInit = TRUE)
  })
}

## test inner ----
test_inner = function(...){
  ui = shiny::fluidPage(
    inner_module_UI("id")
  )
  
  server = function(input, output, session){
    inner_module_Server("id")
  }
  
  shiny::shinyApp(ui, server, ...)
}

## outer ----
outer_module_UI = function(id){
  ns = NS(id)
  
  div(
    hr(),
    inner_module_UI(ns("v1")),
    hr(),
    inner_module_UI(ns("v2")),
    hr()
  )
}

outer_module_Server = function(id) {
  moduleServer(id, function(input, output, session) {
    inner_module_Server("v1")
    inner_module_Server("v2")
  })
}

## test outer ----
test_outer = function(...){
  ui = shiny::fluidPage(
    outer_module_UI("id")
  )
  
  server = function(input, output, session){
    outer_module_Server("id")
  }
  
  shiny::shinyApp(ui, server, ...)
}
