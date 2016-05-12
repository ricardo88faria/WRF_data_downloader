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


my_url <- "ftp://polar.ncep.noaa.gov/pub/history/sst/rtg_low_res/"

data_i <- "2010-01-01" #readline(prompt = "Data inicial para analise de dados no formato (AAAA-MM-DD): ")
data_f <- "2010-02-23" #readline(prompt = "Data final para analise de dados no formato (AAAA-MM-DD): ")

list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
list_dates <- format(list_dates, "%Y%m%d")

file_name <- paste("rtg_sst_grb_0.5.", list_dates, sep = "")

my_list <- as.list(paste(my_url, file_name, sep = ""))

#file <- download.file(as.character(my.list[1]), destfile = as.character(file_name[1]))
#file <- download.file("ftp://polar.ncep.noaa.gov/pub/history/sst/anomaly_grb_0.5.20140612", "tot", mode = "wb")
#GribGrab(my.list[1], latest.pred,levels, variables, verbose = FALSE)
#grb.data <- ReadGrib(file)

for (i in 1:length(file_name)){
  if (file.exists(file_name[i])) {
    cat(paste0(file_name[i], " - already downloaded. \n"))
  } else {
    files <- download.file(as.character(my_list[i]), file_name[i])
  }
}

cat("Download finished with:", "\n", length(file_name), "files")