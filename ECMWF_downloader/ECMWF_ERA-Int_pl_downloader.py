#!/usr/bin/env python
from ecmwfapi import ECMWFDataServer

server = ECMWFDataServer()

#list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
#list_dates <- format(list_dates, "%Y%m%d")

server.retrieve({
    'levelist'  : "all",
    'levtype'   : "pl",
    'param'     : "29/130/131/132/157",
    'dataset'   : "interim",
    'step'      : "0",
    'grid'      : "128",
    'time'      : "00/06/12/18",
    'date'      : "20100701/to/20100701",
    'type'      : "an",
    #'class'     : "ei",
    #'format'    : "netcdf",
    'target'    : "ERA-Int_pl_20100129.grib"
 })
