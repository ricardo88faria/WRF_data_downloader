import os

os.system("source activate python2")


import iris

cubes = iris.load('http://geoport.whoi.edu/thredds/dodsC/fmrc/NCEP/ww3/cfsr/10m/best')

print cubes
