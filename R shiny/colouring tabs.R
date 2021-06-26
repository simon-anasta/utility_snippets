library(shiny)
ui <-shinyUI(fluidPage(
  h1("Colored Tabs"),
  tags$style(HTML("
                  .tabbable > .nav > li > a                  {background-color: aqua;  color:black}
                  .tabbable > .nav > li > a[data-value='tmahaha1'] {background-color: grey;   color:white}
                  .tabbable > .nav > li > a[data-value='t2'] {background-color: blue;  color:white}
                  .tabbable > .nav > li > a[data-value='t3'] {background-color: green; color:white}
                  .tabbable > .nav > li[class=active]    > a {background-color: black; color:white}
                  ")),
  tabsetPanel(
    tabPanel("t0",h2("normal tab")),
    tabPanel("tmahaha1",h2("grey tab")),
    tabPanel("t2",h2("blue tab")), 
    tabPanel("t3",h2("green tab")),
    tabPanel("t4",h2("normal tab")),
    tabPanel("t5",h2("normal tab"))
  )
  ))
server <- function(input, output) {}
shinyApp(ui=ui,server=server)