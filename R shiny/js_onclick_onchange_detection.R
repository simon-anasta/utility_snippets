# Version 1 - buttons
#
# Many of the Shiny components translate into JavaScript. This allows them to be
# run in a browser (browsers support JS but not R).
#
# We have see demonstration of creating buttons directly in JavaScript with
# custom JS executed on click. See here:
# https://www.r-bloggers.com/2021/01/adding-action-buttons-in-rows-of-dt-data-table-in-r-shiny/
#
# This example demonstrates the core of the principal. Note that `js_button1` and `js_button2`
# are very similar to what is created when `actionButton("id", "label")` is run at the console.
# However, they have the addition of the command `onclick=getid(this.id)`.
#
# This function is defined in a separate script and is used to set the value of input$current_id
# in shiny.
# Note that the buttons are not shiny objects. Only input$current_id is.

library(shiny)
library(DT)

js_script_button = '
function get_id(clicked_id) {
     Shiny.setInputValue("current_id", clicked_id, {priority: "event"});
};
'

js_button1 = '<button class="btn btn-default action-button btn-info action_button" id="edit_1" type="button" onclick=get_id(this.id)>edit</button>'

js_button2 = '<button class="btn btn-default action-button btn-info action_button" id="delete_2" type="button" onclick=get_id(this.id)>delete</button>'

ui = fluidPage(
  tags$script(HTML(js_script_button)),
  DTOutput(outputId = "dt_table", width = "100%"),
  strong("last input:"),
  textOutput("last_clicked")
)

server <- function(input, output, session) {
  output$last_clicked = renderText({ input$current_id })
  
  output$dt_table <- DT::renderDT(
    {
      data.frame(b = c(js_button1, js_button2))
    },
    escape = FALSE, # essential, otherwise buttons are just text
    rownames = FALSE,
    options = list(processing = FALSE)
  )
}
# Run the application
shinyApp(ui = ui, server = server)

################################################################################
# Version 2 - selectInput
#
# Building on the version above, we would like the same functionality for
# drop down menus (selectInput and shinyWidgets::pickerInput). However,
# these do not accept `onclick`. Instead they accept `onchange`.
#
# A key limitation here is that onchange does not trigger unless values are changed.
# A minor limitation is picker inputs can how have placeholder text.
#
# We have also bound the selectors to shiny. Hence they can also be accessed
# using input$...

library(shiny)
library(shinyWidgets)
library(DT)

js_selectInput = '
<div class="form-group shiny-input-container">
  <label class="control-label" id="id-label" for="id">label</label>
  <div>
    <select id="id" onchange=get_id(this.id)><option value="1" selected>1</option>
<option value="2">2</option>
<option value="3">3</option></select>
    <script type="application/json" data-for="id" data-nonempty="">{"plugins":["selectize-plugin-a11y"]}</script>
  </div>
</div>
'

js_selectInput2 = '<div class="form-group shiny-input-container">
  <label class="control-label" id="id1-label" for="id1">label2</label>
  <div>
  <select id="id1" onchange=get_id(this.id)><option value="1" selected>1</option>
  <option value="2">2</option>
  <option value="3">3</option></select>
  <script type="application/json" data-for="id1" data-nonempty="">{"plugins":["selectize-plugin-a11y"]}</script>
  </div>
  </div>'

js_picker3 = '<div class="form-group shiny-input-container">
  <label class="control-label" for="picker_id">Placeholder</label>
  <select data-title="This is a placeholder" id="picker_id" class="selectpicker form-control" onchange=get_id(this.id)><option value="a">a</option>
<option value="b">b</option>
<option value="c">c</option>
<option value="d">d</option></select>
</div>'


js_assign = 'function get_id(clicked_id) {
     Shiny.setInputValue("current_id", clicked_id, {priority: "event"});
};
'

ui = fluidPage(
  DT::DTOutput(outputId = "dt_table", width = "100%"),
  tags$head(tags$script(HTML(js_assign))),
  strong("last input via shiny:"),
  textOutput("last_clicked"),
  strong("picker detected via R"),
  textOutput("picker")
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$last_clicked = renderText({ input$current_id })
  output$picker = renderText({ input$picker_id })
  
  output$dt_table <- DT::renderDT(
    {
      data.frame(a = c(js_selectInput, js_selectInput2, js_picker3))
    },
    escape = FALSE,
    rownames = FALSE,
    options = list(
      processing = FALSE,
      preDrawCallback = DT::JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
      drawCallback = DT::JS('function() { Shiny.bindAll(this.api().table().node()); } ')
    )
  )
  
}
# Run the application
shinyApp(ui = ui, server = server)

################################################################################
# Version 3 - with callbacks
#
# The above versions require some manual creation of widgets via HTML code.
# This is unelegant and adds additional complexity.
#
# However, we can add callbacks to buttons and selectizeInput that eliminate
# the need to do this. This result is far superior and our prefered approach.

library(shiny)

js_assign = 'function get_id(clicked_id) {
     Shiny.setInputValue("current_id", clicked_id, {priority: "event"});
};'

ui = fluidPage(
  tags$head(tags$script(HTML(js_assign))),
  selectizeInput(
    "yes",
    "Yes",
    choices = c("a", "b"),
    options = list(onChange = I("function(value) { get_id(this.$input.attr('id')); }")) ### callback as option
  ),
  actionButton("waiting", "Waiting", onclick = "get_id(this.id)"), ### callback
  p(strong("has selectizeInput been changed yet:")),
  textOutput("last_clicked"),
)

server <- function(input, output, session) {
  output$last_clicked = renderText({ input$current_id })
}

shinyApp(ui = ui, server = server)
