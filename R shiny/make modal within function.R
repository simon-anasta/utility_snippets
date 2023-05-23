# test to confirm that modals can be generated AND displayed
# from within a function, not just a reactive.

library(shiny)

complete_modal = function(folder, files){
  
  line1 = paste("Saved", length(files), "files:")
  items = tags$ul(lapply(files, tags$li))
  line3 = paste("into", folder)
  
  showModal(modalDialog(
    title = "Save complete",
    line1,
    items,
    line3,
    footer = tagList(modalButton("OK")),
    easyClose = TRUE
  ))
}


ui = fluidPage(
  actionButton("show", "Show")
)

server = function(input, output, session){
  
  observeEvent(input$show, {
    complete_modal("my_folder", c("file1", "file2"))
  })
}
  

print(shinyApp(ui, server))



