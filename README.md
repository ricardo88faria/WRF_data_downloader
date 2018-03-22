# WRF data downloader

Scripts for download raw data for WPS in WRF,



## Usage:

### Add you account details:

1. ECMWF:
Add file to your home with the follow parameters.
$HOME/.ecmwfapirc
```r
{
    "url"   : "https://api.ecmwf.int/v1",
    "key"   : "XXXXXXXXXXXXXXXXXXXXXX",
    "email" : "*******@example.com"
}
```

2. FNL:
Change you email, password is asked in command line

3. SST:
Dont need account details

### Run it

* Run:
```r
./ECMWF_ERA-Int_pl_downloader.R
./ECMWF_ERA-Int_sfc_downloader.R
./FNL_downloader.R
./SST_downloader.R
```

* kill application:
```r
jobs
kill %process number
```

**Contacts:**

<ricardo88faria@gmail.com>
