library(sf)
library(dplyr)
library(mice)
library(qgisprocess)  
# install.packages("remotes")
#remotes::install_github("paleolimbot/qgisprocess")  //requires a Qgis install 

aadtc  <- st_read("Traffic_Volume.shp") %>% st_transform(28355)
links <- st_read("network.sqlite",stringsAsFactors=F,query ="select * from links")

aadt_network_points <- qgis_run_algorithm(
  "native:pointsalonglines",
  DISTANCE = 10, #map unit distance, here it is meters
  END_OFFSET = 5,
  INPUT = aadtc,#change the input here
  START_OFFSET = 5
)
#convert the temporary point samples to sf object
aadt_network_points_sf <- sf::read_sf(qgis_output(aadt_network_points, "OUTPUT"))

#snap the points to OSM lines with a tolerance
snapaadtOSMlines <- qgis_run_algorithm(
  "native:snapgeometries",
  BEHAVIOR = 1, #prefer closest points insert extra vertices where needed
  INPUT = aadt_network_points_sf,
  REFERENCE_LAYER = links,
  TOLERANCE = 20
)

#snapped points to sf object
snapaadtOSMlines_sf <- sf::read_sf(qgis_output(snapaadtOSMlines, "OUTPUT"))

snapbuffer_aadt <- st_buffer(snapaadtOSMlines_sf, dist = 1)


#very slow, to speed up export and run in qgis after creating spatial index
joinAADTtoosmlines <- qgis_run_algorithm(
  "qgis:joinbylocationsummary",
  DISCARD_NONMATCHING = F,
  INPUT = links,
  JOIN = snapbuffer_aadt,
  SUMMARIES = "median", # 10 is for majority, 7 for median
  JOIN_FIELDS = c('all_Vehs_mm','all_vehs_median')#the column to join the attribute
)

edges <- sf::read_sf(qgis_output(joinAADTtoosmlines, "OUTPUT"))




#edges <- st_read("network_edges.sqlite")



#rank highways
prepimpute <- edges %>% st_drop_geometry() %>% 
  select (ogc_fid0,capacity,freespeed,allvehs_mm_median,allvehs_aa_median,highway)  %>% mutate(highway_num = case_when(
    highway  == 'motorway' ~ 10, highway  == 'trunk'  ~ 9, highway  == 'primary'  ~ 8, highway  == 'secondary'  ~7 ,
    highway  ==  'tertiary'  ~ 6 ,
    highway  ==  'unclassified'  ~ 5 ,highway  == 'residential'  ~ 5 ,highway  == 'motoway_link'  ~ 9 , highway  == 'trunk_link'  ~ 8,  
    highway  ==  'primary_link'  ~ 7 ,highway  =='secondary_link'  ~ 6, highway  == 'tertiary_link'  ~ 5, highway  == 'living_street'  ~ 4,
    highway  == 'service'  ~ 4, highway  == 'pedestrian'  ~ 4,highway  == 'track'  ~ 3, highway  == 'road'  ~ 4,
    highway  ==  'footway'  ~ 1 ,highway  == 'corridor'  ~1 ,highway  ==  'steps'  ~ 1 ,highway  == 'path'  ~ 1, highway  == 'cycleway'  ~ 2
  )  ) %>% as.data.frame()

#prepimpute[,3:4] <- missForest(prepimpute)$ximp[,3:4]

#impute allvehs_mm_median & allvehs_aa_median see metadata for the meaning of these values: http://data.vicroads.vic.gov.au/metadata/Traffic_Volume%20-%20Open%20Data.html
sedgeimp <-  mice(prepimpute, maxit=5, seed=1)

edgesimputed <- complete(sedgeimp)

edgesimp <-edgesimputed %>% select(ogc_fid0,allvehs_mm_median,allvehs_aa_median)
edgesimp <-rename(edgesimp, allvehs_mm_median_imp=allvehs_mm_median,allvehs_aa_median_imp=allvehs_aa_median)

#join both data
edges_joined <- left_join(edges,edgesimp, by='ogc_fid0')

st_write(edges_joined,"network_edges.sqlite",layer ='links')
