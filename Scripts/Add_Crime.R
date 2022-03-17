library(sf)
library(qgisprocess)
library(sqldf)

suburbs <-  st_read("Compressed/Suburb_Melbourne_crimepop/Suburb_Melbourne_crimepop.shp")
network_edges <- st_read("network_edges1.sqlite")
lga <- st_read("CrimeLGA/CrimeLGA/CrimeLGA.shp")
#join attributes intersecting the roads layer
join_crime <-  qgis_run_algorithm(
  "native:joinattributesbylocation",
  INPUT =network_edges,
  METHOD=1,# Take attributes of the feature with largest overlap only
  DISCARD_NONMATCHING = F,
  JOIN = suburbs,
  JOIN_FIELDS = c('Grand_Tota','Total')
  
)

bgedges_crime <- sf::read_sf(qgis_output(join_crime, "OUTPUT")) 


rate_crime <- bgedges_crime %>% mutate('crime_rate'= (Grand_Tota/Total)*100000)
#Export
st_write(rate_crime,"network_edges2.sqlite",layer ='edges')

