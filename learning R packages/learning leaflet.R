########## INITIAL TUTORIAL ON LEAFLET ##############

library(leaflet)

# load default map and add marker
m = leaflet(options = leafletOptions(minZoom = 0, maxZoom = 18)) %>%
  addTiles() %>%
  addMarkers(lng = 174.768, lat = -36.852, popup = "R")

m

?addTiles
?setView

# zoom into
flyTo(m, lng = 174.768, lat = -36.852, zoom = 14)

# add circles from a data frame with lat & long
df = data.frame(lap = 1:10, lonk = rnorm(10))
leaflet() %>% addCircles(data = df, lng = ~lonk, lat = ~lap)

# polygons via sp  package
library(sp)
Sr1 = Polygon(cbind(c(2,4,4,1,2),c(2,3,5,4,2)), hole = FALSE)
Sr2 = Polygon(cbind(c(5,4,2,5),c(2,3,2,2)), hole = FALSE)
Sr3 = Polygon(cbind(c(4,4,5,10,4),c(5,3,2,5,5)), hole = FALSE)
Sr4 = Polygon(cbind(c(5,6,6,5,5),c(4,4,3,3,4)), hole = TRUE)

Srs1 = Polygons(list(Sr1), "s1")
Srs2 = Polygons(list(Sr2), "s2")
Srs3 = Polygons(list(Sr3, Sr4), "s3/4")
SpP = SpatialPolygons(list(Srs1, Srs2, Srs3), 1:3)
leaflet() %>% addPolygons(data = SpP)

ss = Polygons(list(Sr1,Sr2), "ss")
ssq = SpatialPolygons(list(ss))
leaflet() %>% addPolygons(data = ss)
leaflet() %>% addPolygons(data = ssq)

# maps package
library(maps)

mapStats = map("state", fill = TRUE, plot = FALSE)
leaflet(data = mapStats) %>%
  addTiles() %>% # gives us surrounding/other countries
  addPolygons(fillColor = topo.colors(10, alpha = NULL), stroke = FALSE)
# stroke = boarders/outlines  

# other sources of base maps
names(providers)


###################### REPLICATING GGPLOT MAP IN LEAFLET ###############

library(dplyr)
library(ggplot2)
library(leaflet)
library(sf) # shapefile
library(rgdal) # geospatial data abstraction library

# load for map
shp_path = "C:/NotBackedUp/local R dev/debt_A4s/inputs/regional council 2018 SHP"
shp_file = "regional-council-2018-clipped-generalised"
shp_full = paste0(shp_path,"/",shp_file,".shp")

## reading via rgdal package
#
regc_rgdal_read = readOGR(shp_path, shp_file)
# fetch coordinate reference system
this_crs = raster::crs(regc_rgdal_read) %>% as.character()
# convert
regc_rgdal_read_longlat <- spTransform(regc_rgdal_read, CRS("+proj=longlat +datum=WGS84"))

# plot runtime = 12 seconds
leaflet(data = regc_rgdal_read_longlat) %>% addPolygons();

## reading via sf package
#
regc_sf_read = sf::st_read(shp_full, stringsAsFactors = FALSE)
# resample to reduce size
regc_sf_read = sf::st_simplify(regc_sf_read, dTolerance = 1000)
# convert to spatial polygons
regc_sf_read_longlat = sf::as_Spatial(regc_sf_read)

# fetch current coordinate reference system
this_crs = raster::crs(regc_sf_read_longlat) %>% as.character()
# convert to long & lat for leaflet
regc_sf_read_longlat <- spTransform(regc_sf_read_longlat, CRS("+proj=longlat +datum=WGS84"))

# Runtime = 12 seconds full, 1 second, reduced size
leaflet(data = regc_sf_read_longlat) %>% addPolygons()

###### PROJECTIONS NOTES ###########
#
# To plot data with leaflet it must be in latlong form
# The projection can be changed using spTransform
#
# If you want the appearance of the output map to be according to a specific projection
# Then you need to define the projection and pass this as a leaflet option for plotting
# e.g.:

# define projection
crss = leafletCRS(crsClass = "L.Proj.CRS",
                  code = "placeholder",
                  proj4def = this_crs,   # read from map input
                  resolutions = 2^(16:7))
# projection used as output/plotting option
leaflet(data = regc, options = leafletOptions(crs = crss)) %>%
  addPolygons()

############ HEAT MAP BY SHAPE FILE ####################
#
# leaflet is probably not the best choice of package for this purpose
# as it is intended for maps, but this kind of take is more a plot
# but this is a good challenge to to test my understanding (a journeyman's piece)

library(dplyr)

# load for map
shp_path = "C:/NotBackedUp/local R dev/debt_A4s/inputs/regional council 2018 SHP"
shp_file = "regional-council-2018-clipped-generalised"
shp_full = paste0(shp_path,"/",shp_file,".shp")

## reading via sf package
#
regc = sf::st_read(shp_full, stringsAsFactors = FALSE) %>%
  filter(REGC2018_V != "99") %>%                                # remove area outside mainland
  sf::st_simplify(dTolerance = 1000) %>%                        # resample to reduce size
  sf::as_Spatial() # convert to spatial polygons

# current coord system
display_crs = raster::crs(regc) %>% as.character()
display_leaflet_crs = leaflet::leafletCRS(crsClass = "L.Proj.CRS",
                                          code = "placeholder",
                                          proj4def = display_crs,
                                          resolutions = 2^(14:7))

# convert to long & lat for leaflet
regc = sp::spTransform(regc, sp::CRS("+proj=longlat +datum=WGS84"))


leaflet::leaflet(data = regc,
                 # this option sets the display projection equal to the projection we are used to seeing NZ
                 # with both NI & SI of roughly equal sizes, the leaflet default shows SI larger than the NI
                 options = leaflet::leafletOptions(crs = display_leaflet_crs)) %>%
  leaflet::addPolygons(color = "#000000",
                       weight = 2,
                       opacity = 1,
                       fillColor = ~leaflet::colorQuantile("magma", AREA_SQ_KM)(AREA_SQ_KM)) %>%
  leaflet::fitBounds(lng1 = 165,lat1 = -33,lng2 = 180, lat2 = -48)

# colorQuantile & related, all return a function
# hence you pass the same column twice, once inside the generating function as the domain
# and once to the generated function as the values to be mapped.


######## MAKING SENSE OF CRS #################
# display_crs =
# "+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +units=m +no_defs"
#
# projection is tmerc
# base lat & long is 0 & 173
# origin (x_0 & y_0) as given
# units is meters
#
# I interpret this as being that the coordinate points sit on a grid, with units meters
# the origin of this grid (x_0,y_0) sits at lat=0, long=173
#
# I assume the other are
# - rotation of true north-south axis
# - additional 'flattening curve of earth'
