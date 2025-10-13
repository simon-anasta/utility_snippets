################################################################################
# Designing dynamic tiles for terms
# (2 versions: simple and module)
# 
# Each added tile is a button. Clicking a tile/button puts its contents into the
# text box so it can be removed.
# 
# Original design used renderUI and uiOutput for dynamic / responsive rendering
# of the tile-buttons. See 'dynamic_creation_detection_removal.R'.
# However, this makes for a clumsy button listener, because it is trigger on
# button creation & removal, not just on button click.
# 
# Inserting and removing UI components is a more elegant solution.
# > It does require use of IDs for CSS/HTML identification of components, so is
#     not pure R. But this straightforward: mostly just `paste0('#', id)`.
# > It makes observers much simpler: when a new button-tile is created, an
#     observer for the button-tile is created. The observer is created exactly
#     once.
# > There is no way to remove an observed. Once a button-tile is removed the
#     observer sits idle as it can no longer be triggered. Unless a user was
#     creating 100's of such tiles, it is unlikely that these idle observers
#     will have any impact on performance.
# 

################################################################################

library(shiny)

## ui --------------------------------------------------------------------- ----

ui <- fluidPage(
  strong("Ignored terms"),
  # div just taller than default button size
  # needs id for insertUI
  tags$div(id = "button_tiles", style = "height: 38px;"),
  textInput("current_text", "Term to ignore"),
  actionButton("action_add", "Add"),
  actionButton("action_remove", "Remove"),
  actionButton("action_remove_all", "Remove all"),
  p("Internal view"),
  textOutput("term_active")
)

## server ----------------------------------------------------------------- ----


server <- function(input, output, session) {
  
  rv = reactiveValues(
    active_terms = list(),
    num_term_buttons = 0
  )
  
  output$term_active <- renderText({
    paste(rv$active_terms, collapse = "\n")
  })
  
  observeEvent(input$action_add, {
    req(nchar(input$current_text) > 0)
    req(!input$current_text %in% rv$active_terms)

    rv$num_term_buttons = rv$num_term_buttons + 1
    id = paste0("term_button_", rv$num_term_buttons)
    
    insertUI(
      selector = "#button_tiles",
      where = "beforeEnd",
      ui = actionButton(id, input$current_text)
    )
    
    local({
      btn_id = id
      observeEvent(input[[btn_id]], {
        updateTextInput(session, "current_text", value = rv$active_terms[[btn_id]])
      })
    })

    rv$active_terms[[id]] = input$current_text
    updateTextInput(session, "current_text", value = "")
  })

  observeEvent(input$action_remove, {
    req(nchar(input$current_text) > 0)
    req(input$current_text %in% rv$active_terms)
    
    id = names(rv$active_terms)[rv$active_terms == input$current_text]
    removeUI(selector = paste0("#", id))
    
    rv$active_terms[[id]] = NULL
    updateTextInput(session, "current_text", value = "")
  })

  observeEvent(input$action_remove_all, {
    req(length(rv$active_terms) > 0)
    
    for(id in names(rv$active_terms)){
      removeUI(selector = paste0("#", id))
      rv$active_terms[[id]] = NULL
    }
  })

}

shinyApp(ui, server)


################################################################################
# Converted into a module and tested
################################################################################


library(shiny)

## dynamic button tiles - module ui --------------------------------------- ----

dynamic_button_tiles_ui = function(id){
  ns = NS(id)
  tagList(
    strong("Ignored terms"),
    # div just taller than default button size
    # needs id for insertUI
    tags$div(id = ns("button_tiles"), style = "height: 38px;"),
    textInput(ns("current_text"), "Term to ignore"),
    actionButton(ns("action_add"), "Add"),
    actionButton(ns("action_remove"), "Remove"),
    actionButton(ns("action_remove_all"), "Remove all")
  )
}


## dynamic button tiles - module server ----------------------------------- ----

dynamic_button_tiles_server = function(id){
  moduleServer(id, function(input, output, session) {
    
    # reactive values
    rv = reactiveValues(
      active_terms = list(),
      num_term_buttons = 0
    )
    
    # add button
    observeEvent(input$action_add, {
      req(nchar(input$current_text) > 0)
      req(!input$current_text %in% rv$active_terms)
      
      rv$num_term_buttons = rv$num_term_buttons + 1
      id = paste0("term_button_", rv$num_term_buttons)
      
      insertUI(
        selector = paste0("#", session$ns("button_tiles")),
        where = "beforeEnd",
        ui = actionButton(session$ns(id), input$current_text)
      )
      
      local({
        btn_id = id
        observeEvent(input[[btn_id]], {
          updateTextInput(session, "current_text", value = rv$active_terms[[btn_id]])
        })
      })
      
      rv$active_terms[[id]] = input$current_text
      updateTextInput(session, "current_text", value = "")
    })
    
    # remove button
    observeEvent(input$action_remove, {
      req(nchar(input$current_text) > 0)
      req(input$current_text %in% rv$active_terms)
      
      id = names(rv$active_terms)[rv$active_terms == input$current_text]
      removeUI(selector = paste0("#", session$ns(id)))
      
      rv$active_terms[[id]] = NULL
      updateTextInput(session, "current_text", value = "")
    })
    
    # remove all button
    observeEvent(input$action_remove_all, {
      req(length(rv$active_terms) > 0)
      
      for(id in names(rv$active_terms)){
        removeUI(selector = paste0("#", session$ns(id)))
        rv$active_terms[[id]] = NULL
      }
    })

    return(reactive({rv$active_terms}))
  })
}

## outer app -------------------------------------------------------------- ----

ui <- fluidPage(
  dynamic_button_tiles_ui("active_terms"),
  hr(),
  dynamic_button_tiles_ui("active_terms2"),
  hr(),
  uiOutput("module_active_terms"),
)

server <- function(input, output, session) {
  active_terms = dynamic_button_tiles_server("active_terms")
  active_terms2 = dynamic_button_tiles_server("active_terms2")
  
  output$module_active_terms = renderText({
    HTML(paste(
      "First sub-module:",
      paste(unlist(active_terms(), use.names = FALSE), collapse = "\n"),
      "Second sub-module:",
      paste(unlist(active_terms2(), use.names = FALSE), collapse = "\n"),
      sep = "<br/>"
    ))
  })

}

shinyApp(ui = ui, server = server)

