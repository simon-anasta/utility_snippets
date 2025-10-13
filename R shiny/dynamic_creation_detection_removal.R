################################################################################
# Designing dynamic tiles for terms
# VERSION 1 - superceeded by dynamic_insert_remove_ui
# 
# Each added tile is a button. Clicking a tile/button puts its contents into the
# text box so it can be removed.
# 
# Challenges / snags:
# > rv$ids holds the IDs for the buttons. These are needed for both making the
#     buttons and observing all of them. For observing button clicks, we observe
#     a list of all button stages (made by `access_func` at line 115).
# > A side effect of observing all button states is that changes in the
#     existence of a button can also trigger the observer. Hence conditions like
#     `req(sum(new) > 0)` at line 126 and line 127 using current < new to ensure
#     a button has been clicked since last observation.
# > However this was ineffective as button existence and button value value did
#     not update at the same time allowing an observer to trigger on existence
#     change but before value change. This meant that the new button could
#     (temporarily) inherit the value of the old button2.
# > Ultimate solution is to preserve button ids for active term buttons.
#     This requires that the add action button generates the new ID and the new
#     count, and that the remove action button locates the index of the removed
#     term and removes all three of the term, the ID, and the count.
# > The observer for the term buttons still triggers twice each update (once for
#     the existence change and once for the value change) but the `req()`
#     statements now prevent this from completing.
# 

################################################################################

library(shiny)

## helper functions ------------------------------------------------------- ----

# returns a list of all the inputs
access_func = function(input, ids) {
  lapply(ids, function(id){input[[id]]})
}

## ui --------------------------------------------------------------------- ----

ui <- fluidPage(
  p("Ignored terms"),
  # div just taller than default button size
  tags$div(style = "height: 38px;", uiOutput("term_list")),
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
    active_terms = character(),
    ids = character(),
    current = numeric(),
    num_term_buttons = 0
  )
  
  output$term_active <- renderText({
    paste(rv$active_terms, collapse = "\n")
  })
  
  observeEvent(input$action_add, {
    req(nchar(input$current_text) > 0)
    req(!input$current_text %in% rv$active_terms)

    rv$num_term_buttons = rv$num_term_buttons + 1
    rv$active_terms = c(rv$active_terms, input$current_text)
    rv$ids = c(rv$ids, paste0("term_button_", rv$num_term_buttons))
    rv$current = c(rv$current, 0)

    updateTextInput(session, "current_text", value = "")
  }, ignoreInit = TRUE)

  observeEvent(input$action_remove, {
    req(nchar(input$current_text) > 0)
    req(input$current_text %in% rv$active_terms)

    kept_terms = rv$active_terms != input$current_text
    rv$active_terms = rv$active_terms[kept_terms]
    rv$ids = rv$ids[kept_terms]
    rv$current = rv$current[kept_terms]

    updateTextInput(session, "current_text", value = "")
  }, ignoreInit = TRUE)

  observeEvent(input$action_remove_all, {
    rv$active_terms = character()
    rv$ids = character()
    rv$current = numeric()
  }, ignoreInit = TRUE)
  
  output$term_list = renderUI({
    print("making")
    req(length(rv$active_terms) > 0)

    tagList(
      lapply(
        seq_len(length(rv$active_terms)),
        function(jj){
          label = rv$active_terms[jj]
          id = rv$ids[jj]
          actionButton(id, label)
        }
      )
    )
  })
  
  observeEvent({access_func(input, rv$ids)},{
    print("observing")
    new = unlist(access_func(input, rv$ids), use.names = FALSE)
    req(length(rv$active_terms) == length(rv$current))
    req(length(rv$current) == length(new))
    
    # print(rv$active_terms)
    # print(rv$current)
    # print(new)
    # print(rv$ids)

    # req(sum(new) > 0)
    change = which(rv$current < new)[1] # if multiple take the first one
    rv$current = new
    req(!is.na(change))
    # print(change)
    updateTextInput(session, "current_text", value = rv$active_terms[change])
  }, ignoreInit = TRUE)
  
  
}

shinyApp(ui, server)

