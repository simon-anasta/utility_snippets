################################################################################
# 2025-07-18
# Take a GIS Shape file
# for every region, determine all the adjacent regions / neighbours
# 
################################################################################

# required packages
req_packages = c("sf", "spdep", "dplyr")

for(rp in req_packages){
  if(!rp %in% installed.packages()){
    install.packages(rp)
  }
}

# map file
shapefile_file = "C:/NotBackedUp/adjacent_locations/statsnz-territorial-authority-local-board-2025-clipped-SHP/territorial-authority-local-board-2025-clipped.shp"

# reading via sf package
shapefile = sf::st_read(shapefile_file, stringsAsFactors = FALSE)

# neighbours
?spdep::poly2nb
neighbors = spdep::poly2nb(shapefile)

# convert to data frame
adjacency_df <- data.frame(
  polygon = rep(seq_along(neighbors), sapply(neighbors, length)),
  neighbor = unlist(neighbors)
)

print(adjacency_df)

# visualise
plot(sf::st_geometry(shapefile))
plot(neighbors, sf::st_coordinates(sf::st_centroid(shapefile)), add = TRUE, col = "red")

# add names
shapefile_df = as.data.frame(shapefile)
shapefile_df = dplyr::mutate(shapefile_df, index = dplyr::row_number())
shapefile_df = dplyr::select(shapefile_df, index, TALB2025_V, TALB2025_1, TALB2025_2)

results_df = adjacency_df |>
  dplyr::left_join(shapefile_df, by = c("polygon" = "index")) |>
  dplyr::left_join(shapefile_df, by = c("neighbor" = "index"), suffix = c("_poly","_neig"))

write.csv(results_df, "C:/NotBackedUp/adjacent_locations/TALB2025_adjacent.csv")

