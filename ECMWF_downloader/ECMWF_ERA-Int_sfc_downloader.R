#!/usr/bin/env Rscript

#packages:


#limpeza ambiente e objetos:
rm(list=ls())
cat("\014")

#####################################
cat("Autor:", "\n", "Ricardo Faria", "\n")
#####################################

# time sequence
data_i <- "2010-01-01" #readline(prompt = "Data inicial para analise de dados no formato (AAAA-MM-DD): ")
data_f <- "2010-01-03" #readline(prompt = "Data final para analise de dados no formato (AAAA-MM-DD): ")

list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
list_dates <- format(list_dates, "%Y%m%d")

# install python packages dependencies
#system("sudo pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz")

for (i in 1:length(list_dates)) {
  
  if (file.exists(paste0("ERA-Int_sfc_", list_dates[i], ".grib"))) {
    
    cat(paste0("ERA-Int_sfc_", list_dates[i], ".grib"), " - already downloaded. \n")
    
  } else if (file.exists(paste0("ERA-Int_sfc_", list_dates[i], ".nc"))) {
    
    cat(paste0("ERA-Int_sfc_", list_dates[i], ".nc"), " - already downloaded. \n")
    
  } else {
    
    txt <- c("#!/usr/bin/env python", 
             "from ecmwfapi import ECMWFDataServer", 
             "", 
             "server = ECMWFDataServer()", 
             "", 
             "server.retrieve({", 
             "'dataset' : 'interim',", 
             "'step'    : '0',", 
             "'levtype' : 'sfc',", 
             paste0("'date'    : '", list_dates[i], "/to/", list_dates[i], "',"), 
             "'time'    : '00/06/12/18',", 
             "'type'    : 'an',", 
             "'param'   : '172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42',", 
             #"'area'    : '70/-130/30/-60',", 
             "'grid'    : '128',", 
             #"'format'  : 'netcdf',", 
             #paste0("'target'  : 'ERA-Int_sfc_", list_dates[i], ".nc'"), 
             paste0("'target'  : 'ERA-Int_sfc_", list_dates[i], ".grib'"), 
             
             "})")
    
    writeLines(txt, paste0("ECMWF_ERA-Int_sfc_", list_dates[i], ".py"))
    
    cat(paste0("Downloading ECMWF ERA-Int WRF sfc variables, day: ", list_dates[i]), "\n")
    system(command = paste0("python ECMWF_ERA-Int_sfc_", list_dates[i], ".py"), ignore.stdout = F, ignore.stderr = F)
    system(command = paste0("rm -rf ECMWF_ERA-Int_sfc_", list_dates[i], ".py"), ignore.stdout = F, ignore.stderr = F)
    
  }
  
}

cat("Download finished with:", "\n", length(list_dates), "files")
