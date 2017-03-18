#!/usr/bin/env python
from ecmwfapi import ECMWFDataServer

server = ECMWFDataServer()

server.retrieve({
'dataset' : 'era5_test',
'step'    : '0',
'levtype' : 'sfc',
'date'    : '20160115/to/20160115',
'time'    : '00/01/02/03/04/05/06/07/08/09/10/11/12/13/14/15/16/17/18/19/20/21/22/23',
'type'    : 'an',
'param'   : '172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42',
#'grid'      : "0.25/0.25",          # The spatial resolution in ERA5 is 31 km globally on a Gaussian grid. Here we us lat/long with 0.25 degrees, which is approximately the equivalent of 31km.
'grid'    : '128',
'format'  : "netcdf",
'target'  : 'ERA5_sfc_20160115_0.25.nc'  # if format = netcdf change fro .grib to .nc
})
