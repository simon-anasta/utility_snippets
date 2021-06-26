# required packages
library(shiny)
library(tidyverse)

shinyApp(
  ui = fluidPage(
    selectInput("state", "Choose a state:",
                list(`East Coast` = list("NY" = "NY1", "NJ" = "NJ1", "CT" = "CT1"),
                     `West Coast` = c("WA", "OR", "CA"),
                     `Midwest` = c("MN", "WI", "IA"),
                     `other` = "other")
    ),
    textOutput("result")
  ),
  server = function(input, output) {
    output$result <- renderText({
      paste("You chose", input$state)
    })
  }
)

