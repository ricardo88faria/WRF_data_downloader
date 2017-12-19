#!/usr/bin/env python

#==============================================================================
# # if libs not installed, then:
# # ! pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz
#==============================================================================

import os
import datetime
from ecmwfapi import ECMWFDataServer

#data_i = "20160101"
#data_f = "20160115"

dt = datetime.datetime(2010, 1, 1)
end = datetime.datetime(2018, 1, 1)
step = datetime.timedelta(days=1)

date_list = []

while dt <= end:
    date_list.append(dt.strftime('%Y%m%d'))
    dt += step


server = ECMWFDataServer()

for date in date_list :
    if os.path.isfile("ERA5_sfc_" + str(date) + ".grib") :
        print("ERA5_sfc_" + str(date) + ".grib file allready exists")

    else:
        server.retrieve({
                'class'     : "ea",                      # Do not change
                'dataset'   : "era5",                  # Do not change
                'expver'    : "1",                      # Do not change
                'levtype'   : "sfc",
                'param'     : "172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42",
                'step'      : "0",
                'grid'      : "0.3/0.3", # "0.75/0.75",   "0.125/0.125",   "128"
                'time'      : "00/01/02/03/04/05/06/07/08/09/10/11/12/13/14/15/16/17/18/19/20/21/22/23",
                'area'      : "42/333/22/353",
                'date'      : str(date) + "/to/" + str(date),
                'type'      : "an",
                #'class'     : "ei",
                'stream'    : "oper",
                'format'    : "netcdf",
                'target'    : "ERA5_sfc_" + str(date) + ".nc"

        })
