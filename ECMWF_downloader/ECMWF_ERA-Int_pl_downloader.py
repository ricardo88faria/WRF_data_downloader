#!/usr/bin/env python

import os
import datetime
from ecmwfapi import ECMWFDataServer
# if libs not installed, then:
# ! pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz

#data_i = "20110501"
#data_f = "20110701"

dt = datetime.datetime(2006, 8, 18)
end = datetime.datetime(2006, 8, 21)
step = datetime.timedelta(days=1)

date_list = []

while dt <= end:
    date_list.append(dt.strftime('%Y%m%d'))
    dt += step


server = ECMWFDataServer()

for date in date_list :
    if os.path.isfile("ERA-Int_pl" + str(date) + ".grib") :
        print("ERA-Int_pl" + str(date) + ".grib file allready exists")

    else:
        server.retrieve({
            'levelist'  : "all",
            'levtype'   : "pl",
            'param'     : "129/130/131/132/133/157",
            'dataset'   : "interim",
            'step'      : "0",
            'grid'      : "128", # "0.75/0.75",   "0.125/0.125",   "128"
            'time'      : "00/06/12/18",
            'area'      : "42/333/22/353",
            'date'      : str(date) + "/to/" + str(date),
            'type'      : "an",
            'class'     : "ei",
            'stream'    : "oper",
            #'format'    : "netcdf",
            'target'    : "ERA-Int_pl" + str(date) + ".grib"

        })
