#
# Clipping a GeoJSON map to NZ coastline
# Simon Anastasiadis
# 2022-09-30
#

## references ----
#
# https://cran.r-project.org/web/packages/geojsonR/vignettes/the_geojsonR_package.html
# https://gis.stackexchange.com/questions/372599/in-r-how-to-read-in-geojson-file-modify-then-export-back-as-new-geojson-file
# https://gis.stackexchange.com/questions/377964/clip-function-in-the-sf-package-in-r
# https://r-spatial.github.io/sf/
# https://stackoverflow.com/questions/49354393/r-how-do-i-merge-polygon-features-in-a-shapefile-with-many-polygons-reproducib
# 
## setup ----

library(sf)
library(dplyr)

setwd("C:/NotBackedUp/local R dev")

in_file = "./nz-police-district-boundaries-29-april-2021.json"
correct_boundary_file = "./NZ-RC-22.json"
out_file = "./nz-police-district-boundaries-29-april-2021 clipped.json"

## read data ----

map_to_clip = sf::st_read(in_file)
map_w_correct_boundary = sf::st_read(correct_boundary_file)

## check inputs ----

plot(map_to_clip$geometry)
plot(map_w_correct_boundary$geometry)

## clip ----

clipped_map = sf::st_intersection(map_to_clip, map_w_correct_boundary)
plot(clipped_map$geometry)

## dissolve internal boundaries ----

# column names
cols = colnames(map_to_clip)
cols = cols[cols != "geometry"]

dissolved_map = clipped_map %>%
  select(all_of(c(cols, "geometry"))) %>%
  group_by(!!!syms(cols)) %>%
  summarise(geometry = sf::st_union(geometry)) %>%
  ungroup()

## check output ----

plot(map_to_clip$geometry)
plot(dissolved_map$geometry)

## output ----

sf::st_write(dissolved_map, out_file, driver = "GeoJSON")

## reload and test ----

reload = sf::st_read(out_file)
plot(reload$geometry)

