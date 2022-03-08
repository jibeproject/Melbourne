
library(terra)
library(sf)
library(qgisprocess)
library(dplyr)

network_edges <- st_read("network_edges.sqlite")
dem <-  rast("DEM1028355.tif")# elevation 

#drape edges over dem to get Z values
edges_z <- qgis_run_algorithm(
  "native:setzfromraster",
  INPUT = network_edges,
  RASTER = dem,
  BAND=1
)

edges_zoutput <- sf::read_sf(qgis_output(edges_z, "OUTPUT"))

df = NULL
# loop through features in edges layer getting the mean Z value
for (x in 1:(nrow(edges_zoutput))) {
  ogc_fid0 = edges_zoutput[x,1] %>% st_drop_geometry()
  elev =mean(st_z_range(edges_zoutput[x,]))
df = rbind(df, data.frame(ogc_fid0,elev))
}
df_distint <- distinct(df,.keep_all = T)
edges_elev <- left_join(network_edges, df_distint, by='ogc_fid0') #jointables

st_write(edges_elev,"network_edges1.sqlite",layer ='edges')

