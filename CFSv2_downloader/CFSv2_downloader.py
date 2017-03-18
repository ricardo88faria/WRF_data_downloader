#!/usr/bin/env python

### Program to download CFSv2 data to WRF

### if want to use wget or curl:
### program need unix/linux with wget or curl to work

##########################################################################################

# login
email = 'r1c4rd0f4@gmail.com'
password = input('Insert your CFSv2 servers password: ')

# download type 'thredds' or 'modeldata' (ftp)
#down_type = 'thredds'

# edit data to download
startdate = '2006-08-18'
enddate = '2006-08-21'
delta_dias = 1


##########################################################################################





import os
import subprocess
import re
#import datetime


#begin = datetime.datetime(int(str(startdate)[0:4]), int(str(startdate)[4:6]), int(str(startdate)[6:8]))
#end = datetime.datetime(int(str(enddate)[0:4]), int(str(enddate)[4:6]), int(str(enddate)[6:8]))
#step = datetime.timedelta(days=delta_dias)

#var_list = ['p_levels', 'surface', 'cfsv2_analysis_monthlymeans_ipv']

if (int(str(startdate)[0:4]) > 2011) :
    stream = 'dsid=ds094.0&rtype=S&rinfo=dsnum=094.0'

    p_levels_parameters='3%217-0.2-1:0.0.0,3%217-0.2-1:0.1.1,3%217-0.2-1:0.2.2,3%217-0.2-1:0.2.3,3%217-0.2-1:0.3.1,3%217-0.2-1:0.3.5'
    p_levels_level='76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,221,361,362,363,557,562,563,574,577,581,913,914,219'
    p_levels_product='3'
    p_levels_grid_definition='57'
    p_levels_ststep='yes'

    surface_parameters='3%217-0.2-1:0.0.0,3%217-0.2-1:0.1.0,3%217-0.2-1:0.1.13,3%217-0.2-1:0.2.2,3%217-0.2-1:0.2.3,3%217-0.2-1:0.3.0,3%217-0.2-1:0.3.5,3%217-0.2-1:10.2.0,3%217-0.2-1:2.0.0,3%217-0.2-1:2.0.192'
    surface_level='107,221,521,522,523,524,223'
    surface_product='3'
    surface_grid_definition='68'
    surface_ststep='yes'

elif (int(str(startdate)[0:4]) < 2011) :
    enddate = '2011-01-01'

    stream = 'dsid=ds093.0&rtype=S&rinfo=dsnum=093.0'

    p_levels_parameters='3%217-0.2-1:0.0.0,3%217-0.2-1:0.1.1,3%217-0.2-1:0.2.2,3%217-0.2-1:0.2.3,3%217-0.2-1:0.3.1,3%217-0.2-1:0.3.5'
    p_levels_level='76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,221,361,362,363,557,562,563,574,577,581,913,914,219'
    p_levels_product='3'
    p_levels_grid_definition='57'
    p_levels_ststep='yes'

    surface_parameters='3%217-0.2-1:2.0.192,3%217-0.2-1:0.3.5,3%217-0.2-1:0.2.2,3%217-0.2-1:0.2.3,3%217-0.2-1:0.1.0,3%217-0.2-1:0.1.13,3%217-0.2-1:2.0.0,3%217-0.2-1:10.2.0,3%217-0.2-1:0.3.0,3%217-0.2-1:0.0.0'
    surface_level='521,522,523,524,107,223,221'
    surface_product='3'
    surface_grid_definition='62'
    ssurface_tstep='yes'


#date_list = []

#while begin <= end :

#    date_list.append(begin.strftime('%Y%m%d'))
#    begin += step


# create cookie_file

url_login = 'wget --save-cookies cookie_file --post-data="email=' + email + '&passwd=' + password + '&action=login" https://rda.ucar.edu/cgi-bin/login'
subprocess.call(url_login, shell=True, stdin=subprocess.PIPE)


#for i in range(len(date_list)) :

if os.path.isfile('pgbh*.grb2') :
    print('!!!!!! file allready exists !!!!!!')

else :
    url_request = 'wget --load-cookies cookie_file --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + p_levels_parameters + ';product=' + p_levels_product + ';grid_definition=' + p_levels_grid_definition + ';level=' + p_levels_level + '" http://rda.ucar.edu/php/dsrqst-test.php'
    subprocess.call(url_request, shell=True, stdin=subprocess.PIPE)
    url_request = 'wget --load-cookies cookie_file --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + p_levels_parameters + ';product=' + p_levels_product + ';grid_definition=' + p_levels_grid_definition + ';level=' + p_levels_level + '" http://rda.ucar.edu/php/dsrqst.php'
    subprocess.call(url_request, shell=True, stdin=subprocess.PIPE)

    #request_id = open('dsrqst.php')
    #request_id = request_id.readlines()
    #request_id = request_id[12][11:22]

    with open("dsrqst.php") as f:
        for line in f:
            if "ID" in line:
                request_id = line[11:22]

    request_id_num = re.findall('\d+', request_id)[-1]
    
    auth = input('Type yes wen you receive email (' + email + ') confirmation with download authorization for preassure level files.')
    
    url_down = 'wget --load-cookies cookie_file http://rda.ucar.edu/dsrqst/' + request_id + '/wget.' + request_id_num + '.csh'
    #url_down = 'wget -q -O - --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + surface_parameters + ';product=' + surface_product + ';grid_definition=' + surface_grid_definition + ';level=' + surface_level + '" http://rda.ucar.edu/php/dsrqst-test.php'
    subprocess.call(url_down, shell=True, stdin=subprocess.PIPE)

    file = open('wget.' + request_id_num + '.csh', 'r')
    filedata = file.read()
    filedata = filedata.replace("set passwd = 'xxxxxx'", "set passwd = '" + password + "'")
    with open('wget.' + request_id_num + '.csh', 'w') as file:
        file.write(filedata)
    #file = ('wget.' + request_id_num + '.csh', 'w')
    #file.write(filedata)
    subprocess.call('chmod 755 wget.' + request_id_num + '.csh', shell=True, stdin=subprocess.PIPE)

    run_command = './wget.' + request_id_num + '.csh ' + password
    subprocess.call(run_command, shell=True, stdin=subprocess.PIPE)

    subprocess.call('rm -rf login cookie_file dsrqst*php wget.*.csh *rda.ucar.edu*', shell=True, stdin=subprocess.PIPE)

    print(' Pressure levels files download finished !!!')



if os.path.isfile('flxf*.grb2' ) :
    print('!!!!!! file allready exists !!!!!!')

else :
    url_request = 'wget --load-cookies cookie_file --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + surface_parameters + ';product=' + surface_product + ';grid_definition=' + surface_grid_definition + ';level=' + surface_level + '" http://rda.ucar.edu/php/dsrqst-test.php'
    subprocess.call(url_request, shell=True, stdin=subprocess.PIPE)
    url_request = 'wget --load-cookies cookie_file --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + surface_parameters + ';product=' + surface_product + ';grid_definition=' + surface_grid_definition + ';level=' + surface_level + '" http://rda.ucar.edu/php/dsrqst.php'
    subprocess.call(url_request, shell=True, stdin=subprocess.PIPE)

    #request_id = open('dsrqst.php')
    #request_id = request_id.readlines()
    #request_id = request_id[12][11:22]

    with open("dsrqst.php") as f:
        for line in f:
            if "ID" in line:
                request_id = line[11:22]

    request_id_num = re.findall('\d+', request_id)[-1]
    
    auth = input('Type yes wen you receive email (' + email + ') confirmation with download authorization for surface files..')
    
    url_down = 'wget --load-cookies cookie_file http://rda.ucar.edu/dsrqst/' + request_id + '/wget.' + request_id_num + '.csh'
    #url_down = 'wget -q -O - --post-data "' + stream + ';startdate=' + startdate + ' 00:00;enddate=' + enddate + ' 00:00;parameters=' + surface_parameters + ';product=' + surface_product + ';grid_definition=' + surface_grid_definition + ';level=' + surface_level + '" http://rda.ucar.edu/php/dsrqst-test.php'
    subprocess.call(url_down, shell=True, stdin=subprocess.PIPE)

    file = open('wget.' + request_id_num + '.csh', 'r')
    filedata = file.read()
    filedata = filedata.replace("set passwd = 'xxxxxx'", "set passwd = '" + password + "'")
    with open('wget.' + request_id_num + '.csh', 'w') as file:
        file.write(filedata)
    #file = ('wget.' + request_id_num + '.csh', 'w')
    #file.write(filedata)
    subprocess.call('chmod 755 wget.' + request_id_num + '.csh', shell=True, stdin=subprocess.PIPE)

    run_command = './wget.' + request_id_num + '.csh ' + password
    subprocess.call(run_command, shell=True, stdin=subprocess.PIPE)

    subprocess.call('rm -rf login cookie_file dsrqst*php wget.*.csh *rda.ucar.edu*', shell=True, stdin=subprocess.PIPE)

    print(' Surface files download finished !!!')
