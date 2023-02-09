# Test updating of uiOutput component
#
# This setup allows us to have a UI item with cascading updates.
# Button clicks make a change to the outer UI widget.
# This causes the inner UI widget to regenerate as per its original
# instructions.
# Changes to the upper selectInput have flow-on effects to the
# lower selectInput.
#
#
# This approach is superior to our original attempt using two
# observers:
# 1) Observe the upper selectInput and update the lower.
# 2) Observe the button and update both selectInputs.
#
# This approach resulted in cascade updates. A button click
# triggered the second observer leading to updates to both
# selectInputs. The change to the first selectInputs triggered
# the other observer leading to competing updates on the
# second selectInputs.

library(shiny)

v1_list = c("apple", "pear", "banana")
v2_list = c("red", "blue", "green")

ui = fluidPage(
  actionButton("button", "Button"),
  textInput("default", "Default", value = "green"),
  uiOutput("main"),
  hr(),
  textOutput("display1"),
  textOutput("display2")
)

server = function(input, output, session) {
  
  output$main = renderUI({
    tagList(
      strong(paste("Button clicks", input$button)),
      selectInput("layer1", label = "Layer 1", choices = c("V1", "V2"), selected = "V1"),
      uiOutput("sub")
    )
  })
  
  output$sub = renderUI({
    # conditional choice of list
    if(input$layer1 == "V1"){
      this_list = v1_list
    } else if(input$layer1 == "V2"){
      this_list = v2_list
    }
    # use default if provided
    if(input$default %in% this_list){
      this_value = input$default
    } else {
      this_value = this_list[1]
    }
    selectInput("layer2", label = "Layer 2", choices = this_list, selected = this_value)
  })
  
  output$display1 = renderText({ input$layer1 })
  output$display2 = renderText({ input$layer2 })
}

shinyApp(ui, server)
