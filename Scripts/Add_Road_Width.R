library(dplyr)
library(sf)
library(qgisprocess)
library(missForest)

network <- st_read("network_edges2.sqlite") %>% st_transform(28355)
road_width <- st_read("CrimeLGA/road_width.shp")

pointalong <- qgis_run_algorithm(
  "native:pointsalonglines",
  INPUT = road_width,
  DISTANCE = 20,
  START_OFFSET =5,
  END_OFFSET =5
)

pointsalong <- st_read(qgis_output(pointalong, "OUTPUT"))

snap <- qgis_run_algorithm(
  "native:snapgeometries",
  INPUT=pointsalong,
  REFERENCE_LAYER=network,
  BEHAVIOR=1
)

snapped <- st_read(qgis_output(snap,"OUTPUT"))

join <- qgis_run_algorithm(
  "native:joinattributesbylocation",
  INPUT=network,
  JOIN=snapped,
  PREDICATE=0,
  JOIN_FIELDS=c('SEAL_WIDTH'),
  METHOD=1,
  DISCARD_NONMATCHING=F,
)

joined <- st_read(qgis_output(join,"OUTPUT"))

net <- st_read("CrimeLGA/network.sqlite")
 g <- left_join(network,net %>% st_drop_geometry() %>%select(ogc_fid0,seal_width),by="ogc_fid0")

