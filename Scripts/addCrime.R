library(sf)
library(qgisprocess)

network_edges <- st_read("network_edges1.sqlite")
lga <- st_read("CrimeLGA/CrimeLGA/CrimeLGA.shp")
#join attributes intersecting the roads layer
join_crime <-  qgis_run_algorithm(
  "native:joinattributesbylocation",
  INPUT =network_edges,
  DISCARD_NONMATCHING = F,
  JOIN = lga,
  JOIN_FIELDS = c('Sum_of_Inc','Sum_of_PSA','Sum_of_LGA')
  
)

edges_crime <- sf::read_sf(qgis_output(join_crime, "OUTPUT")) 
#export
st_write(edges_elev,"network_edges2.sqlite",layer ='edges')
