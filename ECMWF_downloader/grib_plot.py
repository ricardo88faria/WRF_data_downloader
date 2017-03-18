import pygrib
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from mpl_toolkits.basemap import Basemap
import numpy as np
 
plt.figure(figsize=(12,8))
 
grib='ERA5_sfc_20160115.grib' # Set the file name of your input GRIB file
grbs=pygrib.open(grib)
 
grb = grbs.select()[0]
data=grb.values
print max(data[0])
lat,lon = grb.latlons() # Set the names of the latitude and longitude variables in your input GRIB file
 
m=Basemap(projection='cyl', llcrnrlon=-180, \
  urcrnrlon=180.,llcrnrlat=lat.min(),urcrnrlat=lat.max(), \
  resolution='c')
 
x, y = m(lon,lat)
 
cs = m.pcolormesh(x,y,data,shading='flat',cmap=plt.cm.hot, norm=colors.LogNorm())
 
m.drawcoastlines()
m.drawmapboundary()
m.drawparallels(np.arange(-90.,120.,30.),labels=[1,0,0,0])
m.drawmeridians(np.arange(-180.,180.,60.),labels=[0,0,0,1])
 
plt.colorbar(cs,orientation='vertical', shrink=0.5)
plt.title('CAMS GFAS fire radiative power (W / m2)') # Set the name of the variable to plot
plt.savefig('gfas_05.png') # Set the output file name
plt.show()