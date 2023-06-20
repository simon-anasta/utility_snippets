#' Test detection of row and column selection using DT::datatable
#' 
#' Observations:
#' - both row and column selection work
#' - row counts start from 1 but column counts start from 0
#' - if row names are included these become column 0
#' - handling of unselection different from selection
#'   - unselected values can not be printed
#'   - unselection may not trigger observers
#' - selections can be set using proxies
#' 

library(shiny)

## UI definition -------------------------------------------------------- ----
ui = fluidPage(
  hr(),
  DT::dataTableOutput("horizontal_dt"),
  hr(),
  DT::dataTableOutput("vertical_dt"),
  hr(),
  hr(),
  "Horizontal",
  shiny::textOutput("horizontal_selection"),
  "Vertical",
  shiny::textOutput("vertical_selection"),
  hr(),
  actionButton("select", "Select")
)

## server definition ---------------------------------------------------- ----
server = function(input, output, session){
  # data
  df = as.data.frame(matrix(1:20,4,5,TRUE))
  
  # display
  output$horizontal_dt = DT::renderDataTable({
    DT::datatable(
      df, 
      class = "compact",
      rownames = FALSE,
      selection = list(
        mode = "single"
      ),
      options = list(
        dom = "t",
        ordering = FALSE,
        pageLength = -1
      )
    )
  })
  
  output$vertical_dt = DT::renderDataTable({
    DT::datatable(
      df, 
      class = "compact",
      rownames = FALSE,
      selection = list(
        mode = "single",
        target = "column" # makes it vertical selection
      ),
      options = list(
        dom = "t",
        ordering = FALSE,
        pageLength = -1
      )
    )
  })
  
  # proxies
  proxy_horizontal_dt = DT::dataTableProxy('horizontal_dt')
  proxy_vertical_dt = DT::dataTableProxy('vertical_dt')
  
  # listeners
  output$horizontal_selection = renderText({
    input$horizontal_dt_rows_selected
  })
  
  output$vertical_selection = renderText({
    input$vertical_dt_columns_selected
  })
  
  # selector
  observeEvent(input$select, {
    DT::selectRows(proxy_horizontal_dt, selected = 2)
    DT::selectColumns(proxy_vertical_dt, selected = 2)
  })
}

## run app -------------------------------------------------------------- ----
shinyApp(ui, server)
