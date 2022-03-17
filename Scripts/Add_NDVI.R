library(terra)
library(dplyr)
library(qgisprocess)
library(sf)

network_edges <-  st_read("network_edges2.sqlite")
ndvi <-  rast("melbourne_ndvi5.tif")

buffer = st_buffer(network_edges,20)

zonal_stats <- qgis_run_algorithm(
  "native:zonalstatisticsfb",
  INPUT=buffer,
  INPUT_RASTER=ndvi,
  RASTER_BAND=1,
  STATISTICS=2,#MEAN
  
)

buff_mean <- sf::read_sf(qgis_output(zonal_stats, "OUTPUT"))

edges_ndvi <- left_join(network_edges,buff_mean %>% st_drop_geometry() %>% select(ogc_fid0,X_mean) %>% rename(ndvi_mean=X_mean), by='ogc_fid0')
max(edges_ndvi$ndvi_mean,na.rm = T)
min(edges_ndvi$ndvi_mean,na.rm = T)
summary(edges_ndvi$ndvi_mean)

#GEE code
# //geometry extent of network
# var geometry = ee.Geometry( { "type": "Polygon", "coordinates": [ [ [ 144.116407031441611, -38.543011287588527 ], [ 145.921154440730078, -38.573569169952009 ], [ 145.940628703589852, -37.227560601028479 ], [ 144.168384849823013, -37.198439077251955 ], [ 144.116407031441611, -38.543011287588527 ] ] ] });
# geometry.geodesic = true
# //zoom to location
# Map.centerObject(geometry);
# //select S2 collection and filter by geometry,date and cloud cover(less than 20%)
# var s2 = ee.ImageCollection('COPERNICUS/S2_SR').filterBounds(geometry).filterDate('2021-01-01','2022-03-14').filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10));
# 
# //view no of images in collection
# //int(s2);
# var bandNameExp = '(b("B8") - b("B4")) / (b("B8") + b("B4"))';
# 
# var calc_ndvi = function(image){
#   return image.addBands(image.expression(bandNameExp).rename('NDVI'));
# };
# var ndvi_collection = s2.map(calc_ndvi);
# 
# //int(ndvi_collection);
# 
# var meanndvi = ndvi_collection.select('NDVI').mean();
# print(meanndvi);
# 
# var ndviVis = {min:0, max:1, palette: ['blue','white','green']};
# Map.addLayer(meanndvi.clip(geometry), ndviVis, 'meanndvi');
# Export.image.toDrive({
#   image: meanndvi,
#   description: 'meanndvi_m',
#   folder: 'sentinel',
#   fileNamePrefix: 'melbourne_ndvi',
#   region: geometry,
#   scale: 20,
#   maxPixels: 1e9,
#   crs:'EPSG:28355'
# });
