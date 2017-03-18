#!/usr/bin/env python
from ecmwfapi import ECMWFDataServer

server = ECMWFDataServer()

#list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
#list_dates <- format(list_dates, "%Y%m%d")

server.retrieve({
    #'stream'    : "oper",
    'levtype'   : "sfc",
    'param'     : "172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42",
    'dataset'   : "interim",
    'step'      : "0",
    'grid'      : "128",
    'time'      : "00/06/12/18",
    'date'      : "20100701/to/20100701",
    'type'      : "an",
    'class'     : "ei",
    #'format'    : "netcdf",
    'target'    : "ERA-Int_sfc_20100701.grib"
 })
