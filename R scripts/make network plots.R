# make network plot
# 2024-01-05
# 
# Using igraph and networkD3
# 
# References:
# https://r-graph-gallery.com/257-input-formats-for-network-charts.html
# https://r-graph-gallery.com/network-interactive.html
# 

## setup ----------------------------------------------------------------------

setwd("path/to/file/goes/here")
library(dplyr)

df = readxl::read_xlsx("file name.xlsx", "sheet name")

# input is a two column sheet
# one row per edge
# column_1 = edge start/from node
# column 2 = edge end/to node

## igraph method --------------------------------------------------------------

colnames(df) = c("source", "target")
network = igraph::graph_from_data_frame(d=df, directed=TRUE)

# plot to default display
plot(network)

# plot to file
png(filename = "tmp.png", width = 1980, height = 1480, units = "px", pointsize = 10, bg = "white", res = NA)
plot(network, vertex.size=8)
dev.off()

## networkD3 - undirected -----------------------------------------------------

colnames(df) = c("from", "to")
myplot = networkD3::simpleNetwork(df, height="100px", width="100px")

# plot to viewer
print(myplot)

## networkD3 - directed -------------------------------------------------------
#
# the directed graph requires a different function call
# and this needs some deliberate setup

colnames(df) = c("from", "to")
node_names = unique(c(df$from, df$to))

node_df = data.frame(
  names = sort(node_names),
  ids = 0:(length(node_names) - 1),
  group = 1
)

links_df = df %>%
  dplyr::inner_join(node_df, by = c("from" = "names")) %>%
  dplyr::rename(from_id = ids) %>%
  dplyr::inner_join(node_df, by = c("to" = "names")) %>%
  dplyr::rename(to_id = ids) %>%
  dplyr::mutate(value = 1)

myplot = networkD3::forceNetwork(
  Links = links_df,
  Nodes = node_df,
  Source = "from_id",
  Target = "to_id",
  Value = "value",
  NodeID = "names",
  Group = "group",
  arrows = TRUE,
  opacityNoHover = 1,
  charge = -90
)
print(myplot)
