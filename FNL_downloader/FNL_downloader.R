#!/usr/bin/env Rscript

#packages:
#library(rgdal)
#library(rNOMADS)

#limpeza ambiente e objetos:
rm(list=ls())
cat("\014")

#####################################
cat("Autor:", "\n", "Ricardo Faria", "\n")
#####################################

# rda.ucar.edu account details:
email = "*********@gmail.com"
pass = "*********"

data_i <- "2010-01-01" #readline(prompt = "Data inicial para analise de dados no formato (AAAA-MM-DD): ")
data_f <- "2010-01-03" #readline(prompt = "Data final para analise de dados no formato (AAAA-MM-DD): ")

seq_dates <- seq(as.POSIXct(data_i), as.POSIXct(data_f), by = "6 hour")
list_dates <- format(seq_dates, "%Y%m%d_%H_00")
file_name <- paste0("fnl_", list_dates, ".grib2") #as.list(paste(my_url, file_name, sep = ""))

# login into rda.ucar.edu server
#login_link <- paste0("https://rda.ucar.edu/cgi-bin/login")
down_link <- paste0("http://rda.ucar.edu/data/ds083.2/grib2/", format(seq_dates, "%Y"), "/", format(seq_dates, "%Y.%m"),"/fnl_", list_dates, ".grib2")
system(paste0("wget -O Authentication.log --save-cookies auth.rda_ucar_edu  --post-data 'email=", email, "&passwd=", pass, "&action=login' https://rda.ucar.edu/cgi-bin/login"))


for (i in 1:length(file_name)){
  
  if (file.exists(file_name[i])) {
    
    cat(paste0(file_name[i], " - already downloaded. \n"))
    
  } else {
    
    system(paste0("wget -N --load-cookies auth.rda_ucar_edu ", down_link[i]))
    
  }
}

system(paste0("rm -rf Authentication.log auth.rda_ucar_edu"))

cat("Download finished with:", "\n", length(file_name), "files")