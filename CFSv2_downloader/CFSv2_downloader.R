library(ncdf4)

url_grid <- "http://rda.ucar.edu/opendap/d6lSf713Wi"

nc <- nc_open(url_grid)

# names(nc$var)

ISBL <- ncvar_get(nc, "HGT_ISBL")
U <- ncvar_get(nc, "U_GRD_ISBL")


nc_create('test.nc', tets)
