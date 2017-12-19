#!/usr/bin/env python

import os
import datetime
from ecmwfapi import ECMWFDataServer
# if libs not installed, then:
# ! pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz

#data_i = "20160101"
#data_f = "20160115"

dt = datetime.datetime(2011, 6, 12)
end = datetime.datetime(2011, 6, 19)
step = datetime.timedelta(days=1)

date_list = []

while dt <= end:
    date_list.append(dt.strftime('%Y%m%d'))
    dt += step


server = ECMWFDataServer()

for date in date_list :
    if os.path.isfile("ERA-Int_sfc_" + str(date) + ".grib") :
        print("ERA-Int_sfc_" + str(date) + ".grib file allready exists")

    else:
        server.retrieve({
            #'stream'    : "oper",
            'levtype'   : "sfc",
            'param'     : "172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42",
            'dataset'   : "interim",
            'step'      : "0",
            'grid'      : "128", # "0.75/0.75",   "0.125/0.125",   "128"
            'time'      : "00/06/12/18",
            'area'      : "42/328/22/355",
            'date'      : str(date) + "/to/" + str(date),
            'type'      : "an",
            'class'     : "ei",
            'stream'    : "oper",
            #'format'    : "netcdf",
            'target'    : "ERA-Int_sfc_" + str(date) + ".grib"

        })
