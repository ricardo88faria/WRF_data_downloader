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

# user input resolution ("low" or "high"):
res = "high"
data_i <- "2017-01-09"
data_f <- "2017-01-10"

if (res == "low") {
  
  my_url <- "http://polar.ncep.noaa.gov/pub/history/sst/rtg_low_res/"
  
} else if (res == "high") {
  
  my_url <- "ftp://polar.ncep.noaa.gov/pub/history/sst/rtg_high_res/"
  
}

if (res == "low") {
  
  list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
  list_dates <- format(list_dates, "%Y%m%d")
  
} else if (res == "high" & data_i <= "2012-12-31" & data_f <= "2012-12-31") {
  
  list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "month")
  list_dates <- format(list_dates, "%Y%m")
  
} else if (res == "high" & data_i <= "2012-12-31" & data_f >= "2012-12-31") {
  
  list_dates <- seq.Date(as.Date(data_i), as.Date("2012-12-31"), by = "month")
  list_dates <- c(format(list_dates, "%Y%m"), format(seq.Date(as.Date("2012-12-31"), as.Date(data_f), by = "day"), "%Y%m%d"))
  #list_dates <- format(list_dates, "%Y%m%d")
  
} else if (res == "high" & data_i >= "2012-12-31" & data_f >= "2012-12-31") {
  
  list_dates <- seq.Date(as.Date(data_i), as.Date(data_f), by = "day")
  list_dates <- format(list_dates, "%Y%m%d")
  
}



if (res == "low") {
  
  file_name <- paste("rtg_sst_grb_0.5.", list_dates, sep = "")

} else if (res == "high") {
  
  file_name <- paste("rtg_sst_grb_hr_0.083.", list_dates, sep = "")
  
}

my_list <- as.list(paste(my_url, file_name, sep = ""))

#file <- download.file(as.character(my.list[1]), destfile = as.character(file_name[1]))
#file <- download.file("ftp://polar.ncep.noaa.gov/pub/history/sst/anomaly_grb_0.5.20140612", "tot", mode = "wb")
#GribGrab(my.list[1], latest.pred,levels, variables, verbose = FALSE)
#grb.data <- ReadGrib(file)

for (i in 1:length(file_name)){
  if (file.exists(file_name[i])) {
    
    cat(paste0(file_name[i], " - already downloaded. \n"))
    
  } else {
    
    if (res == "high" & list_dates[i] <= "2012-12-31") {
      
      files <- download.file(paste0(as.character(my_list[i]), ".gz"), paste0(file_name[i], ".gz"))
      #system(paste0("wget -N ", as.character(my_list[i])))
      system(paste0("gzip -d ", file_name[i], ".gz"))
      system(paste0("mv ", file_name[i], " ", file_name[i], ".grib"))
    
    } else if (res == "high" & list_dates[i] >= "2012-12-31") {
      
      files <- download.file(as.character(my_list[i]), paste0(file_name[i], ".grib"))
      
    } else if (res == "low") {
      
      files <- download.file(as.character(my_list[i]), paste0(file_name[i], ".grib"))
      
    }
  }
}

cat("Download finished with:", "\n", length(file_name), "files")
