library(highcharter)
library(ncdf4)
library(raster)
#library(ggmap)
#library(maps)
library(rworldmap)
library(rworldxtra)

source("matrix_rotation.R")

# read item scan(what = numeric(0),n = 1)

# user info: need ncl path in bash
# user input config:
N = 33.3
S = 30 #32.1
E = -15.8
O = -20 #-17.9


# to arrange the plots 
#split.screen() 


file_low <- list.files(path = "low_res", pattern = "rtg_sst_grb_0.5.") 
file_high <- list.files(path = "high_res", pattern = "rtg_sst_grb_hr_") 


list_dates <- sub("rtg_sst_grb_0.5.", "\\1", file_low)
list_dates <- sub(".nc", "\\1", list_dates)

list_dates <- seq.Date(as.Date(list_dates[1], "%Y%m%d"), as.Date(list_dates[length(list_dates)], "%Y%m%d"), by = "day")


netcdf_low_list <- nc_open(paste0("low_res/", file_low))
netcdf_high_list <- nc_open(paste0("high_res/", file_high))

lat_low_Idx <- c(which(netcdf_low_list$dim$lat_235$vals >= S & netcdf_low_list$dim$lat_235$vals <= N))
lon_low_Idx <- c(which(netcdf_low_list$dim$lon_235$vals >= 360-abs(O) & netcdf_low_list$dim$lon_235$vals <= 360-abs(E)))
lat_high_Idx <- c(which(netcdf_high_list$dim$lat_173$vals >= S & netcdf_high_list$dim$lat_173$vals <= N))
lon_high_Idx <- c(which(netcdf_high_list$dim$lon_173$vals >= 360-abs(O) & netcdf_high_list$dim$lon_173$vals <= 360-abs(E)))
lat_low_values <- netcdf_low_list$dim$lat_235$vals[lat_low_Idx]
lon_low_values <- netcdf_low_list$dim$lon_235$vals[lon_low_Idx]-360
lat_high_values <- netcdf_high_list$dim$lat_173$vals[lat_high_Idx]
lon_high_values <- netcdf_high_list$dim$lon_173$vals[lon_high_Idx]-360

#netcdf_lat <- ncvar_get(netcdf_low_list, "lat_235")
#netcdf_lon <- ncvar_get(netcdf_low_list, "lon_235")
netcdf_low <- list()
count = 0
for (i in file_low) {
  
  count = count + 1
  netcdf_low_list <- nc_open(paste0("low_res/", i))
  netcdf_low[[count]] <- ncvar_get(netcdf_low_list, "TMP_235_SFC")[rev(lon_low_Idx), lat_low_Idx]
  
}
#netcdf_low_test <- array(unlist(netcdf_low), dim=c(ncol(netcdf_low[[1]]), nrow(netcdf_low[[1]]), length(file_low)))

netcdf_high <- list()
netcdf_high_temp <- list()
count = 0
count_2 = 0
for (i in file_high) {
  
  count = count + 1
  netcdf_high_list <- nc_open(paste0("high_res/", i))
  netcdf_high_temp <- ncvar_get(netcdf_high_list, "TMP_173_SFC")[rev(lon_high_Idx), lat_high_Idx,]
  for (j in 1:length(netcdf_high_temp[1, 1, ])) {
   
    count_2 = count_2 + 1
    netcdf_high[[count_2]] <- netcdf_high_temp[ , , j]
    print(count_2)
  }
  
}
rm(netcdf_high_temp)
#netcdf_high <- list(ncvar_get(netcdf_high_list, "TMP_173_SFC")[lon_high_Idx, lat_high_Idx,])


rasterOptions(timer = T, progress = "text")

rast_high <- c()
netcdf_high_deg <- c()
for (i in 1:length(netcdf_high)){      
  
  netcdf_high_deg[[i]] = netcdf_high[[i]] - 273.15
  
  temp <- raster(mat_rot(netcdf_high_deg[[i]]), 
                 xmn = lon_high_values[1], xmx = lon_high_values[length(lon_high_values)], 
                 ymn = lat_high_values[length(lat_high_values)], ymx = lat_high_values[1], 
                 CRS("+proj=longlat +datum=WGS84"))
  rast_high <- c(rast_high, temp)
  
}
rast_low <- c()
netcdf_low_deg <- c()
anoma_low_high <- c()
for (i in 1:length(netcdf_low)){      
  
  netcdf_low_deg[[i]] = netcdf_low[[i]] - 273.15
  
  temp <- raster(mat_rot(netcdf_low_deg[[i]]), 
                 xmn = lon_low_values[1], xmx = lon_low_values[length(lon_low_values)], 
                 ymn = lat_low_values[length(lat_low_values)], ymx = lat_low_values[1], 
                 CRS("+proj=longlat +datum=WGS84"))
  
  # Create a raster with the desired dimensions, and resample into it
  rast_low_dim <- raster(nrow = length(lat_low_values), ncol = length(lon_low_values))
  temp <- resample(temp, rast_high[[1]])
  
  # merge
  rast_low <- c(rast_low, temp)

  # anomalie
  temp_an <- rast_low[[i]] - rast_high[[i]]
  anoma_low_high <- c(anoma_low_high, temp_an)
  
}


# graph setup
rgb.palette=colorRampPalette(c("darkblue","palegreen1","yellow","red2"),interpolate="spline")

newmap <- getMap(resolution = "high")
image(x = lon_low_values, 
      y = rev(lat_low_values), 
      netcdf_low[[1]], asp = 1
      #xlim = c(-17.5, -16.4), ylim = c(32.3, 33.2)
      )
image(x = lon_high_values, 
      y = rev(lat_high_values), 
      netcdf_high[[1]], asp = 1
      #xlim = c(-17.5, -16.4), ylim = c(32.3, 33.2)
      )
plot(newmap,
     asp = 1.0, col = "gray", add = T)


filled.contour(lon_high_values, rev(lat_high_values), mat_rot(as.matrix(rast_high[[45]])), 
               color.palette = rgb.palette, asp = 1,
               plot.title = title(main = "Sea Surface Temperature [º]", xlab = "Longitude [°]", ylab = "Latitude [°]"),
               plot.axes = {axis(1); axis(2); plot(newmap, asp = 1.0, col = "gray", add = T)})

filled.contour(lon_high_values, rev(lat_high_values), mat_rot(as.matrix(rast_low[[30]])), 
               color.palette = rgb.palette, asp = 1,
               plot.title = title(main = "Sea Surface Temperature [º]", xlab = "Longitude [°]", ylab = "Latitude [°]"),
               plot.axes = {axis(1); axis(2); plot(newmap, asp = 1.0, col = "gray", add = T)})

filled.contour(lon_high_values, rev(lat_high_values), mat_rot(as.matrix(anoma_low_high[[30]])), 
               color.palette = rgb.palette, asp = 1,
               plot.title = title(main = "Sea Surface Temperature [º]", xlab = "Longitude [°]", ylab = "Latitude [°]"),
               plot.axes = {axis(1); axis(2); plot(newmap, asp = 1.0, col = "gray", add = T)})

