#!/usr/bin/env python

### Program to download MERRA2 data to WRF

### if want to use wget or curl:
### program need unix/linux with wget or curl to work
### create .netrc file at your home with 'machine urs.earthdata.nasa.gov login <uid> password <password>'

### if want to use pydap:   compatible with python2 only
### you must install pydap first 'pip install pydap -U' & 'pip install pydap.responses.netcdf'

##########################################################################################

# download type 'http' or 'ftp' (netcdf only!!! area select dont work, must download all globe area!!! uses a lot of hdd space!!!)
down_type = 'http'

# edit data to download
data_i = 20110610
data_f = 20110620
delta_dias = 1

# edit area to download
N = 42
S = 22
E = -7
W = -27

# data format 'hdf', 'nc4c' (netcdf4 classic) or 'nc4' (netcdf4)
data_format = 'nc4'


##########################################################################################





import os
import subprocess
import datetime


begin = datetime.datetime(int(str(data_i)[0:4]), int(str(data_i)[4:6]), int(str(data_i)[6:8]))
end = datetime.datetime(int(str(data_f)[0:4]), int(str(data_f)[4:6]), int(str(data_f)[6:8]))
step = datetime.timedelta(days=delta_dias)

#stream_list = ['MERRA2_100', 'MERRA2_200', 'MERRA2_300', 'MERRA2_400']
var_list = ['const_2d_asm_Nx', 'tavg1_2d_slv_Nx', 'tavg1_2d_ocn_Nx', 'inst6_3d_ana_Nv', 'inst6_3d_ana_Np']
url_letetr_list = ['M2C0NXASM', 'M2T1NXSLV', 'M2T1NXOCN', 'M2I6NVANA', 'M2I6NPANA']
url_nr_list = ['4', '4', '4', '5', '5']


if data_format == 'nc4' :
    format = 'bmM0Lw'
    extention = 'nc4'
elif data_format == 'nc4c' :
    format = 'bmM0Yy8'
    extention = 'nc4'
elif data_format == 'hdf' :
    format = 'aGRmLw'
    extention = 'hdf'
else :
    print(" Wrong data format change it to 'hdf' or 'nc4' !!! ")

date_list = []

while begin <= end :

    date_list.append(begin.strftime('%Y%m%d'))
    begin += step


### Download constant data (land data)

if os.path.isfile('MERRA2_101.const_2d_asm_Nx.00000000') :    #('MERRA2_400.' + str(var_list[0]) + '.00000000.' + extention) :
    print('!!!!!! MERRA2_101.const_2d_asm_Nx.00000000 file allready exists !!!!!!')

else :
    url = 'wget https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2C0NXASM.5.12.4/1980/MERRA2_101.const_2d_asm_Nx.00000000.nc4'
    # backup link           https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2C0NXASM.5.12.4/1980/MERRA2_101.const_2d_asm_Nx.00000000.nc4
    #                       https://goldsmr4.sci.gsfc.nasa.gov/opendap/hyrax/MERRA2_MONTHLY/M2C0NXASM.5.12.4/1980/MERRA2_101.const_2d_asm_Nx.00000000.nc4.html
    # hdf but merra1        https://goldsmr2.gesdisc.eosdis.nasa.gov/data/MERRA_MONTHLY/MAC0NXASM.5.2.0/1979/MERRA300.prod.assim.const_2d_asm_Nx.00000000.hdf
    #

    subprocess.call(url, shell=True, stdin=subprocess.PIPE)
    print(' Download finished:  MERRA2_101.const_2d_asm_Nx.00000000')

    # crop box
    #cdo sellonlatbox,-27,-7,22,42 MERRA2_400.const_2d_asm_Nx.00000000.nc MERRA2_400.const_2d_asm_Nx.00000000_crop.nc

### Download time variable data (climatic data)

if down_type == 'ftp' :

    for i in range(len(date_list)) :

        if (int(str(date_list[i])[0:4]) >= 1980 and int(str(date_list[i])[0:4]) <= 1991) :
            stream = 'MERRA2_100'

        elif (int(str(date_list[i])[0:4]) >= 1992 and int(str(date_list[i])[0:4]) <= 2000) :
            stream = 'MERRA2_200'

        elif (int(str(date_list[i])[0:4]) >= 2001 and int(str(date_list[i])[0:4]) <= 2010) :
            stream = 'MERRA2_300'

        elif (int(str(date_list[i])[0:4]) >= 2011) :
            stream = 'MERRA2_400'

        for l in range(1,len(var_list)) :

            if os.path.isfile(stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention) :
                print('!!!!!! ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention + ' file allready exists !!!!!!')

            else :
                url = 'wget --no-passive-ftp ftp://goldsmr' + str(url_nr_list[l]) + '.sci.gsfc.nasa.gov/data/s4pa/MERRA2/' + str(url_letetr_list[l]) + '.5.12.4/' + str(date_list[i][0:4]) + '/' + str(date_list[i][4:6]) + '/' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.nc4 -O ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.nc4'
                #url = 'wget --no-check-certificate -O ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention + ' --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies https://goldsmr' + str(url_nr_list[l]) + '.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi\?FILENAME\=%2Fdata%2FMERRA2%2F' + str(url_letetr_list[l]) + '.5.12.4%2F' + str(date_list[i][0:4]) + '%2F' + str(date_list[i])[4:6] + '%2F' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.nc4\&FORMAT\=' + format + '\&BBOX\=' + str(S) + '%2C' + str(W) + '%2C' + str(N) + '%2C' + str(E) + '\&LABEL\=' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.SUB.' + extention + '\&FLAGS\=\&SHORTNAME\=' + str(url_letetr_list[l]) + '\&SERVICE\=SUBSET_MERRA2\&LAYERS\=\&VERSION\=1.02\&VARIABLES\=  --content-disposition'
                subprocess.call(url, shell=True, stdin=subprocess.PIPE)
                print(' Download finished:  ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention)


elif down_type == 'http' :

    for i in range(len(date_list)) :

        if (int(str(date_list[i])[0:4]) >= 1980 and int(str(date_list[i])[0:4]) <= 1991) :
            stream = 'MERRA2_100'

        elif (int(str(date_list[i])[0:4]) >= 1992 and int(str(date_list[i])[0:4]) <= 2000) :
            stream = 'MERRA2_200'

        elif (int(str(date_list[i])[0:4]) >= 2001 and int(str(date_list[i])[0:4]) <= 2010) :
            stream = 'MERRA2_300'

        elif (int(str(date_list[i])[0:4]) >= 2011) :
            stream = 'MERRA2_400'

        for l in range(1,len(var_list)) :

            if os.path.isfile(stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention) :
                print('!!!!!! ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention + ' file allready exists !!!!!!')

            else :
                url = 'wget --no-check-certificate -O ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention + ' --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies https://goldsmr' + str(url_nr_list[l]) + '.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi\?FILENAME\=%2Fdata%2FMERRA2%2F' + str(url_letetr_list[l]) + '.5.12.4%2F' + str(date_list[i][0:4]) + '%2F' + str(date_list[i])[4:6] + '%2F' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.nc4\&FORMAT\=' + format + '\&BBOX\=' + str(S) + '%2C' + str(W) + '%2C' + str(N) + '%2C' + str(E) + '\&LABEL\=' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.SUB.' + extention + '\&FLAGS\=\&SHORTNAME\=' + str(url_letetr_list[l]) + '\&SERVICE\=SUBSET_MERRA2\&LAYERS\=\&VERSION\=1.02\&VARIABLES\=  --content-disposition'
                subprocess.call(url, shell=True, stdin=subprocess.PIPE)
                print(' Download finished:  ' + stream + '.' + str(var_list[l]) + '.' + str(date_list[i]) + '.' + extention)

else :
    print('  Download type not recognized, select download type http or ftp  ')


### not used for now ###
#import urllib
#urllib.urlretrieve('https://goldsmr5.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FMERRA2%2FM2I6NPANA.5.12.4%2F2016%2F01%2FMERRA2_400.inst6_3d_ana_Np.20160811.nc4&FORMAT=bmM0Lw&BBOX=22%2C-27%2C42%2C-7&LABEL=MERRA2_400.inst6_3d_ana_Np.20160811.SUB.nc4&FLAGS=&SHORTNAME=M2I6NPANA&SERVICE=SUBSET_MERRA2&LAYERS=&VERSION=1.02&VARIABLES=')

#import wget
#wget.download('https://goldsmr5.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FMERRA2%2FM2I6NPANA.5.12.4%2F2016%2F01%2FMERRA2_400.inst6_3d_ana_Np.20160811.nc4&FORMAT=bmM0Lw&BBOX=22%2C-27%2C42%2C-7&LABEL=MERRA2_400.inst6_3d_ana_Np.20160811.SUB.nc4&FLAGS=&SHORTNAME=M2I6NPANA&SERVICE=SUBSET_MERRA2&LAYERS=&VERSION=1.02&VARIABLES=', bar=None)




### experimental !!! ###


#from pydap.client import open_url
#from pydap.responses.netcdf import save

#import sys
#sys.path.append('pydap_responses_netcdf')
#from . import pydap_responses_netcdf
#import pydap_responses_netcdf

#dataset = open_url('https://goldsmr4.gesdisc.eosdis.nasa.gov/opendap/MERRA2/M2T1NXSLV.5.12.4/2016/06/MERRA2_400.tavg1_2d_slv_Nx.20160601.nc4')
#save(dataset, 'test_netcdf.nc4')


#f=netCDF4.Dataset('test.nc', 'w')
