#' Test shinyWidgets radio buttons with different horizontal scaling
#' 
#' Observations:
#' - horizontal scaling depends on whether justified = T/F
#' - justified = T
#'   - all button are same size
#'   - text will overflow out the left side of button
#' - justified = F
#'   - button size determined by text size
#'   - buttons will spill to new row if too long
#' - New line characters can's be inserted into button text
#' - size argument only controls vertical size
#' - feasibility
#'   - for short text 10 buttons is possible
#'   - for longer text only 5 buttons is possible
#' - if we want the best of both worlds,
#'   then we will need a custom widget - perhaps build as module
#' 

library(shiny)
library(shinyWidgets)

global_justified = TRUE

options_short = c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J")
options_long = c(
  "Aaaaaaaaaaaaaaa",
  "Bbbbbbbbbbbbbbb",
  "Ccccccccccccccc",
  "Ddddddddddddddd",
  "Eeeeeeeeeeeeeee",
  "Fffffffffffffff",
  "Ggggggggggggggg",
  "Hhhhhhhhhhhhhhh",
  "Iiiiiiiiiiiiiii",
  "Jjjjjjjjjjjjjjj"
)

## ui generation function ------------------------------------------------- ----

width_option = function(width, justified) {
  div(
    fluidRow(
      paste0("width = ", width),
      hr(),
      column(
        width = width,
        radioGroupButtons(
          inputId = paste0("short", width),
          label = "Label",
          choices = options_short,
          size = "sm",
          justified = justified
        ),
        radioGroupButtons(
          inputId = paste0("long", width),
          label = "Label",
          choices = options_long,
          justified = justified
        )
      )
    ),
    hr()
  )
}

## UI definition -------------------------------------------------------- ----
ui = fluidPage(
  width_option(4, global_justified),
  width_option(8, global_justified),
  width_option(12, global_justified)
)

## server definition ---------------------------------------------------- ----
server = function(input, output, session){
  
}

## run app -------------------------------------------------------------- ----
shinyApp(ui, server)
