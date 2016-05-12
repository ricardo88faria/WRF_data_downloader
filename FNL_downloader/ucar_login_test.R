library(httr)
terms <- "https://rda.ucar.edu/cgi-bin/login"
download <- "http://rda.ucar.edu/data/ds083.2/grib2/2010/2010.02/fnl_20100201_00_00.grib2"

values <- list(email = "***********@gmail.com", passwd = "********", action = "login")

# Accept the terms on the form, 
# generating the appropriate cookies
test <- POST(terms, body = values)
GET(download, query = values)

# Actually download the file (this will take a while)
resp <- GET(download, query = values)

# write the content of the download to a binary file
writeBin(content(resp, "raw"), "lala.grib2")



#install.packages("http://www.omegahat.net/RHTMLForms/RHTMLForms_0.6-0.tar.gz", repos = NULL)
library(RHTMLForms)
library(RCurl)
require(XML)

#create connection function from login form
login<-getHTMLFormDescription("http://mysite//Login.php")  
login<-login$Login
submit<-createFunction(login)

#create section with cookiefile 
curl = getCurlHandle(cookiefile = "", verbose = TRUE)

#Log in
submit(Password=mypass,User=myuser,.curl = curl )

#now I can navigate on the site
my_page<-getURL("http://mysite/table.php?id=988", curl = curl)

#I get for the id 988 an Url png image
my_picture<-getHTMLExternalFiles(my_page)[1]
my_picture<-paste("http://mysite/",my_picture,sep="")

myBin <- getBinaryURL(my_picture, curl = curl)
writeBin(myBin, "my_pic.png")