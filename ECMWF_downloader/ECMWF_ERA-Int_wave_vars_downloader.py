#!/usr/bin/env python

import os
import datetime
from dateutil.relativedelta import relativedelta
from ecmwfapi import ECMWFDataServer
# if libs not installed, then:
# ! pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz


dt = datetime.datetime(1990, 1, 1)
end = datetime.datetime(2016, 12, 31)
#step = datetime.timedelta(days=365)
step = relativedelta(years=1)

date_list = []

while dt <= end:
    date_list.append(dt.strftime('%Y%m%d'))
    dt += step
#datestring = "/".join(datelist)

server = ECMWFDataServer()

for i in range(len(date_list)) :
    if os.path.isfile("ERA-Int_wave_" + str(date_list[i]) + "_" + str(date_list[i+1]) + ".grib") :
        print("ERA-Int_wave_" + str(date_list[i]) + "_" + str(date_list[i+1]) + ".grib file allready exists")

    else:
        server.retrieve({
            'stream'    : "WAVE",
            'levtype'   : "sfc",
            'param'     : "113.140/232.140/230.140/200.140/218.140/229.140", #/190.500/185.500/3102",
            'dataset'   : "interim",
            'step'      : "0",
            'grid'      : "0.125/0.125", # "0.75/0.75",
            'time'      : "00/06/12/18",
            'date'      : str(date_list[i]) + "/to/" + date_list[i+1],  # datestring
            'type'      : "AN",
            'class'     : "EI",
            'area'      : "33.75/342/32.25/344.25",
            'format'    : "netcdf",
            'target'    : "ERA-Int_wave_" + str(date_list[i]) + "_" + str(date_list[i+1]) + ".nc"

        })
