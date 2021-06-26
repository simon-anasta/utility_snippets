## approach 1 -----------------------------------

# library
library(sankey)
library(dplyr)

# functions
sankey_edges = function(input_table, keyword, colour){
  output_table = input_table %>%
    filter(group == keyword) %>%
    mutate(from = paste0(x_from,as.character(y_from)),
           to = paste0(x_to,as.character(y_to)),
           weight = num,
           colorstyle = 'solid',
           col = colour
    ) %>%
    select(from, to, weight, colorstyle, col)
  
  return(output_table)
}

last_two_characters = function(x){
  substr(x, nchar(x)-2+1, nchar(x))
}

all_but_last_two_characters = function(x){
  substr(x, 1, nchar(x)-2)
}

type_to_y = function(in_list){
  in_list[in_list == 'state 1'] = '1'
  in_list[in_list == 'state 2'] = '2'
  in_list[in_list == 'state 3'] = '3'
  in_list[in_list == 'state 4'] = '4'
  
  return(as.numeric(in_list))
}


type_to_colour = function(in_list){
  in_list[in_list == 'state 1'] = "coral4"
  in_list[in_list == 'state 2'] = "orange4"
  in_list[in_list == 'state 3'] = "darkgreen"
  in_list[in_list == 'state 4'] = "goldenrod"
  
  return(in_list)
}

# load
sankey_transitions = read.csv('sankey_transitions.csv')

# make edges data set
group_A = sankey_edges(sankey_transitions,"A","blue")
group_B = sankey_edges(sankey_transitions,"B","red")
group_C = sankey_edges(sankey_transitions,"C","gray")

edge_set = rbind(group_A, group_B, group_C)

# make node data set
node_list = unique(c(edge_set$from, edge_set$to))

node_set = data.frame(
  name = node_list,
  x = as.numeric(last_two_characters(node_list)),
  y = type_to_y(all_but_last_two_characters(node_list)),
  shape = "rectangle",
  label = all_but_last_two_characters(node_list),
  col = type_to_colour(all_but_last_two_characters(node_list)),
  boxw = 0.5,
  stringsAsFactors = FALSE
)

# formats
node_set = as.data.frame(node_set)
edge_set = as.data.frame(edge_set)
edge_set = edge_set[edge_set$weight != 0,]

# manual locations
sankey_components = make_sankey(node_set, edge_set, y = 'simple')

max_width = sankey_components$nodes %>% summarise(val = max(size)) %>% as.numeric()

node_set$y = node_set$y * 0.7 * max_width

# plot sankey
sankey_components = make_sankey(node_set, edge_set, y = 'simple')

png('demo sankey.png', 1500, 900)
sankey(sankey_components, mar = c(10,5,0,5))
axis(1,
     at = c(15,17,19,21,23,25,27,29,31,33,35),
     labels = c(15,17,19,21,23,25,27,29,31,33,35),
     cex.axis = 1.5)
dev.off()

## approach 2 -----------------------------------

edges = read.csv('edges_trial.csv', stringsAsFactors = FALSE)
nodes = read.csv('nodes_trial.csv', stringsAsFactors = FALSE)
edges = edges[edges$weight != 0,]
sankey(make_sankey(nodes, edges))
sankey(make_sankey(edges = edges))
