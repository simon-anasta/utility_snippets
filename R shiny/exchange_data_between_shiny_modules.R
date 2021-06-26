library(shiny)
library(shinydashboard)
library(shinyWidgets)

dropDownUI <- function(id, div_width = "col-xs-12 col-md-8") {
  
  ns <- NS(id)
  
  div(column(3, uiOutput(ns("class_level"))),
      column(3,uiOutput(ns("selected_product_ui"))
      ))
}

chartTableBoxUI <- function(id, div_width = "col-xs-12 col-md-8") {
  ns <- NS(id)
  
  div(tabBox(width = 12, title = id,
             tabPanel(icon("bar-chart"),
                      textOutput(ns("selected_var")))
  )
  )
}

chartTableBox <- function(input, output, session, data,a) {
  
  output$selected_var <- renderText({
    ns <- session$ns
    paste("You have selected",a())
  })
}

dropDown <- function(input, output, session) {
  
  ns <- session$ns
  
  observe({output$class_level <- renderUI({
    selectInput(
      ns("selected_class"),
      label = h4("Classification Level"),
      choices = list(
        "apple " = "apple",
        "orange " = "orange"),
      selected = "orange"
    )})
  })
  
  a<-reactive({input$selected_class})
  
  output$selected_product_ui <- renderUI({
    req(input$selected_class)
    Sys.sleep(0.2)
    ns <- session$ns
    
    if (input$selected_class == "apple") {
      my_choices <- c("foo","zoo","boo")
    } else if (input$selected_class == "orange") {
      my_choices <- c("22","33","44")
    } else {
      my_choices <- c("aa","bb","cc")
    }
    
    selectInput(inputId = ns("selected_product"),
                label = h4("Product Family"),
                choices = my_choices)
  })
  
  return(a)
}

sidebar <- dashboardSidebar(sidebarMenu(
  menuItem("aaa",tabName = "aaa"),
  menuItem("bbb", tabName = "bbb"),
  menuItem("ccc", tabName = "ccc")
))

body <-   ## Body content
  dashboardBody(tabItems(
    tabItem(tabName = "aaa",
            fluidRow(dropDownUI(id = "dropdown"),
                     fluidRow(chartTableBoxUI(id = "ATC2"))
            )
    )))
# Put them together into a dashboardPage
ui <-   dashboardPage(
  dashboardHeader(title = "Loyalty Monthly Scorecard"),
  sidebar,
  body
)

server = {
  shinyServer(function(input, output, session) {
    a = callModule(dropDown, id = "dropdown")
    callModule(chartTableBox, id = "ATC2", data = MyData, a = a)
    
  })
}

shinyApp(ui = ui, server = server)