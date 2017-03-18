#!/usr/bin/env Rscript

#packages:


#limpeza ambiente e objetos:
rm(list=ls())
cat("\014")

# copy grib file to a separate folder and run .R in the same folder
# user configs:
# nome do/s ficheiros
pattern_name = "rtg_sst_grb_0.5"
convertor = "ncl_convert2nc"

#####################################
cat("Autor:", "\n", "Ricardo Faria", "\n")
#####################################

file_list <- list.files(pattern = pattern_name) 

if (convertor == "wgrib") {
  for (i in file_list) {
    
    system(paste0(convertor, " ", i, " -netcdf " , i, ".nc"))
    
  }
} else if (convertor == "wgrib2") {
  for (i in file_list) {
    
    system(paste0(convertor, " ", i, " -netcdf " , i, ".nc"))
    
  }
} else if (convertor == "ncl_convert2nc") {
  for (i in file_list) {
    
    system(paste0(convertor, " ", i))
    
  }
} else {
  
  print("Unknow convertor!!!")
  
}
