#############################################
# Alcoholic Anonymous meetings chloropleth  #
# map by local authority / county in R      #
#                                           #
# Date: October 2018                        #
# Author: Gaskyk                            #
#############################################

library(maptools)
library(leaflet)
library(htmltools)

# Read in shapefile
# Source: http://geoportal.statistics.gov.uk/datasets/counties-and-unitary-authorities-december-2017-ultra-generalised-clipped-boundaries-in-england-and-wales
cnty_ua = readShapePoly("xx/Counties_and_Unitary_Authorities_December_2017_Ultra_Generalised_Clipped_Boundaries_in_Great_Britain.shp")

# If type proj4string(las), the projection system is NA. Actually we use the British
# National Grid so need to convert that (http://spatialreference.org/ref/epsg/27700/)
# Then convert to WGS84 using the odd strings below
proj4string(cnty_ua) <- CRS("+init=epsg:27700")
cnty_ua_trans <- spTransform(cnty_ua, CRS("+proj=longlat +datum=WGS84"))

# Read in data about AA meetings per 100,000 population
meeting_count <- read.csv("xx/aa_meetings_per_pop.csv",
                   stringsAsFactors = FALSE)

# Merge spatial polygon with meetings data
cnty_ua_meetings <- sp::merge(cnty_ua_trans, meeting_count, by.x="ctyua17cd", by.y="AreaCode")

# Prepare bins
bins <- c(0, 2.5, 5, 7.5, 10, 15, 20, 100, Inf)
pal <- colorBin("YlOrRd", domain = cnty_ua_meetings$meetings_per_pop, bins = bins)

# Create hover-over labels
labels <- sprintf(
  "<strong>%s</strong><br/>%g per 100,000",
  cnty_ua_meetings$AreaName, cnty_ua_meetings$meetings_per_pop
) %>% lapply(htmltools::HTML)

# Create the map
m <- leaflet(cnty_ua_meetings) %>%
  setView(lng = -3, lat = 55, zoom = 6) %>%
  addTiles(urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") %>%
  addPolygons(  fillColor = ~pal(meetings_per_pop),
                weight = 2,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(
                  weight = 5,
                  color = "#666",
                  dashArray = "",
                  fillOpacity = 0.7,
                  bringToFront = TRUE),
                label = labels,
                labelOptions = labelOptions(
                  style = list("font-weight" = "normal", padding = "3px 8px"),
                  textsize = "15px",
                  direction = "auto")) %>%
  addLegend(pal = pal, values = ~meetings_per_pop, opacity = 0.7, title = NULL,
                                                 position = "bottomright")
m




