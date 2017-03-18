#!/usr/bin/perl -w
#
# This routine converts grib1 to grib2 metadata
#  The name of the grib1 is passed
#
# only handles simple grib1 files
#
#  The grib2 metadata is written to $out.meta
#  The binary output is written to $out.bin
#
# for perl beginners
#  \d    matches any digit
#  \d*   matches any number of digits
#  \s    matches any whitespace
#  \S    matches any non-whitespace
#
# 3/14/2011 - make the grib1 > grib2 metadata converter into a perlscript
# v1.0
# 3/2014: copied grib1to2_meta.pl to grib1to2_metadata.pl, this version
#         retains earth, radius, center, subcenter and process id of grib file
#         introduced with grib1to2_v3.pl
# 4/2/2014: set BVF2, PV___ to IMGD
# 4/3/2014: valid XX-YYhr -> XX-YY hour ave fcst, T=XXXK, added dot for XXX.XXK, PREIX -> IMGD
#           MAXVIG XX hr fcst -> GRPL (XX-1)-XX hour max fcst
# 4/8/2014 RERRVAR -> REV
# 1/13/2016: old ecmwf Z (m**2/s**2) -> HGT (m)
#                this is wrong now ecmwf Z -> GP
#                ecmwf GH (m) -> HGT (m)
# 1/19/2016: added ens mean, ens spread, ENS=xxx
# 4/7/2016: added ECMWF: 10U 10V 2T
# 9/22/2016: added ECMWF: 2D
$metadata_version = "2016.9.22 NCEP/CPC";

sub grib1to2_metadata_version() {
  print $metadata_version;
}

sub grib2_metadata{

    my $my_file = $_[0];

    # input: verbose inventory and write data as a f77 binary file
    if (! defined($wgrib)) { $wgrib = 'wgrib'; }

print ">> grib2_metadata --- $file   wgrib=$wgrib wgrib2=$wgrib2\n";

    open (INV, "$wgrib -V $file -d all -bin -h -o $out.bin |");

    # input:  simple inventory
    open (INS, "$wgrib -s -4yr $file |");

    # output: metadata file
    open (META, ">$out.meta");



# read verbose and simple inventories
# in verbose inventory, end of record is found by a blank line

$line="";
$n=0;
while (<INV>) {
    chomp;                            # strip record separator
    $line="$line $_";


    # check if end of verbose inventory
    if ("$_" eq "") { 
        $_=$line;

#       read scaling

	/ DecScale (-*\d*) BinScale (-*\d*)/;
	$dec_scale=-$1;
	$bin_scale=$2;

#       read metadata
        / center *(\S*) subcenter *(\S*) *process *(\S*)/;
        $center=$1;
        $subcenter=$2;
        $process=$3;

        / mode  *(\S*) / or die "no scan mode";
        $mode=$1;
        $radius= ($mode & 64) / 32;

#       read simple inventory
        $line_simple=<INS>;
#       for ECMWF files
	$line_simple =~ s/:type=[a-zA-Z0-9]*:/:/;
        chomp($line_simple);

# print ">>>>A $line_simple\n";

#       scan for ensemble info
	$ens="";

        if ($line_simple =~ s/:ensemble:mean:/:/) {
            $ens="ens mean";
        }
        if ($line_simple =~ s/:ensemble:std dev:/:/) {
            $ens="ens std dev";
        }

        if ($line_simple =~ s/:ens([+-][0-9]+):/:/) {
	    if ($1 eq '+0') { $ens='ENS=hi-res ctl'; }
	    elsif ($1 eq '-0') { $ens='ENS=low-res ctl'; }
	    else { $ens="ENS=$1"; }
        }



# print ">>> ens=$ens\n";
# print ">>>>B $line_simple\n";

        ($n,$byte,$date,$var,$lev,$ftime,$ave,$nave) = split(':',$line_simple,9);

#       most grib1 metadata is the same as grib2 metadata
#       special cases:  grib1 metadata into grib2 metadata

	if ($lev eq 'sfc') { $lev = 'surface'; }
	elsif ($lev eq 'MSL') { $lev = 'mean sea level'; }
	elsif ($lev eq 'nom. top') { $lev = 'top of atmosphere'; }
	elsif ($lev eq 'cld base') { $lev = 'cloud base'; }
	elsif ($lev eq 'cld top') { $lev = 'cloud top'; }
	elsif ($lev eq 'high cld lay') { $lev = 'high cloud layer'; }
	elsif ($lev eq 'mid cld lay') { $lev = 'middle cloud layer'; }
	elsif ($lev eq 'low cld lay') { $lev = 'low cloud layer'; }
	elsif ($lev eq 'convect-cld layer') { $lev = 'convective cloud layer'; }
	elsif ($lev eq 'high cld top') { $lev = 'high cloud top level'; }
	elsif ($lev eq 'mid cld top') { $lev = 'middle cloud top level'; }
	elsif ($lev eq 'low cld top') { $lev = 'low cloud top level'; }
	elsif ($lev eq 'convect-cld top') { $lev = 'convective cloud top level'; }
	elsif ($lev eq 'high cld bot') { $lev = 'high cloud bottom level'; }
	elsif ($lev eq 'mid cld bot') { $lev = 'middle cloud bottom level'; }
	elsif ($lev eq 'low cld bot') { $lev = 'low cloud bottom level'; }
	elsif ($lev eq 'convect-cld bot') { $lev = 'convective cloud bottom level'; }
        elsif ($lev =~ s/ m above gnd/ m above ground/) { }
	elsif ($lev eq 'max wind lev') { $lev = 'max wind'; }
	elsif ($lev eq 'planetary boundary layer (from Richardson no.)') { $lev = 'planetary boundary layer'; }
	elsif ($lev eq 'cond lev') { $lev = 'level of adiabatic condensation from sfc'; }


	$lev =~ s/^lowest level of wet bulb zero$/lowest level of the wet bulb zero/;
	$lev =~ s/^max wind lev$/max wind/;
	$lev =~ s/ m above MSL$/ m above mean sea level/;
	$lev =~ s/^high trop freezing lvl$/highest tropospheric freezing level/;
	$lev =~ s/ mb above gnd/ mb above ground/;
	$lev =~ s/sigma=(.*)/$1 sigma level/;
	$lev =~ s/hybrid lev (.*)/$1 hybrid level/;
	$lev =~ s/bndary-layer cld layer/boundary layer cloud layer/;
	$lev =~ s/^([0-9.]*)K$/$1 K isentropic level/;
	$lev =~ s/^T=([0-9.]*)K$/$1 K level/;
	$lev =~ s/ocean mixed layer bot/bottom of ocean mixed layer/;
	$lev =~ s/ocean isothermal layer bot/bottom of ocean isothermal layer/;
	$lev =~ s/sfc-26C ocean layer/layer ocean surface and 26C ocean isothermal level/;

	if ($lev =~ /^(-*[\d.]*) pv units/) {
	    $t=$1 * 1e-9;
	    $lev = "PV=$t (Km^2/kg/s) surface";
	}
	if ($lev =~ /^sigma ([\d.]*)-([\d.]*)/) {
	    $lev="$1-$2 sigma layer";
	}
	if ($lev =~ /^(\d*) cm down/) {
	    $t=0.01 * $1;
	    $lev = "$t m underground";
	}
	if ($lev =~ /^(\d*)-(\d*) cm down/) {
	    $s=0.01 * $1;
	    $t=0.01 * $2;
	    $lev = "$s-$t m below ground";
	}	
	if ($lev =~ /^(\d*)-(\d*)m ocean layer$/) {
	    $lev = "$1-$2 m below sea level";
	}
	if ($lev =~ /^([-]*\d*\.*\d*)C ocean isotherm level$/) {
	    $lev = "${1}C ocean isotherm";
        }


        if ($ave =~ 'ave@([0-9]*)hr') {
           $dt=$1;
           $nave =~ s/NAve=//;
	   if ($ftime eq 'anl') {
               $ftime = $nave . '@' . $dt . ' hour ave anl,missing=0';
           }
           elsif ($ftime =~ '(.*-.*)hr fcst') {
               $ftime = $nave . '@' . $dt . ' hour ave(' . $1 . ' hour ave fcst),missing=0';
           }
           elsif ($ftime =~ '(.*)hr fcst') {
               $ftime = $nave . '@' . $dt . ' hour ave(' . $1 . ' hour fcst),missing=0';
           }
        }

# printf ">>> ftime=$ftime\n";
# for forecasts
	if ($conv eq 'fcst') {
	$ftime =~ s/hr ave$/ hour ave fcst/;
	$ftime =~ s/hr acc$/ hour acc fcst/;
	$ftime =~ s/d ave$/ day ave fcst/;
	$ftime =~ s/d acc$/ day acc fcst/;
	$ftime =~ s/mon ave$/ month ave fcst/;
	$ftime =~ s/mon acc$/ month acc fcst/;
	$ftime =~ s/^valid (\d*)-(\d*)hr$/$1-$2 hour ave fcst/;
	$ftime =~ s/^(\d*)-(\d*)d product$/$1-$2 day ave fcst/;
	$ftime =~ s/^(\d*)-(\d*)mon product$/$1-$2 mon ave fcst/;
	}
# for analysis
	else {
	$ftime =~ s/hr ave$/ hour ave anl/;
	$ftime =~ s/hr acc$/ hour acc anl/;
	$ftime =~ s/d ave$/ day ave anl/;
	$ftime =~ s/d acc$/ day acc anl/;
	$ftime =~ s/mon ave$/ month ave anl/;
	$ftime =~ s/mon acc$/ month acc anl/;
	$ftime =~ s/^valid (\d*)-(\d*)hr$/$1-$2 hour ave anl/;
	$ftime =~ s/^(\d*)-(\d*)d product$/$1-$2 day ave anl/;
	$ftime =~ s/^(\d*)-(\d*)mon product$/$1-$2 month ave anl/;
	}

#printf ">>>> ftime=$ftime\n";
	$ftime =~ s/^([-+]*\d*) *to *([-+]*\d*) /$1-$2 /;
#printf ">>>>> ftime=$ftime\n";
#

	$ftime =~ s/^(\d*)hr fcst$/$1 hour fcst/;
	$ftime =~ s/^(\d*)hr anl$/$1 hour anl/;

	if ($var eq  'TMAX') { $ftime =~ s/valid (.*)hr/$1 hour max fcst/; }
	if ($var eq  'QMAX') { $ftime =~ s/valid (.*)hr/$1 hour max fcst/; }
	if ($var eq  'TMIN') { $ftime =~ s/valid (.*)hr/$1 hour min fcst/; }
	if ($var eq  'QMIN') { $ftime =~ s/valid (.*)hr/$1 hour min fcst/; }

	if ($var eq 'CBTW') { $var='COVTW'; }
        elsif ($var eq 'CBUQ') { $var='COVQZ'; }
        elsif ($var eq 'CBVQ') { $var='COVQM'; }
        elsif ($var eq 'CBQW') { $var='COVQVV'; }
	elsif ($var eq 'CBUQ') { $var='COVQZ'; }
	elsif ($var eq 'CBTZW') { $var='COVTZ'; }
	elsif ($var eq 'CBTMW') { $var='COVTM'; }
	elsif ($var eq 'CBMZW') { $var='COVMZ'; }
	elsif ($var eq 'FRIME') { $var='RIME'; }
	elsif ($var eq 'RUNOF') { $var='WATR'; }
	elsif ($var eq 'SNOEV') { $var='SBSNO'; }
	elsif ($var eq 'RHCLD') { $var='CDLYR'; }
	elsif ($var eq 'SGLYR') { $var='MLYNO'; }
	elsif ($var eq 'VSSH') { $var='VWSH'; }
	elsif ($var eq 'ICNG') { $var='TIPD'; }
	elsif ($var eq 'GRMR') { $var='GRLE'; }
        elsif ($var eq 'RERRVAR') { $var = 'REV'; }
        elsif ($var eq 'MAXVIG') {
           $var='MAXVIGGG';
           if ($ftime =~ '(\d*) hour fcst') {
              $a1=$1;
              $a0=$a1-1;
              $var='GRLE';
              $ftime="$a0-$a1 hour max fcst";
           }
        }         
	elsif ($var eq 'SDTRH') { $var='IMGD'; $undef++; }
	elsif ($var eq 'BVF2') { $var='IMGD'; $undef++; }
	elsif ($var eq 'PV___') { $var='IMGD'; $undef++; }
	elsif ($var eq 'PREIX') { $var='IMGD'; $undef++; }
        elsif ($var eq 'CBUW') { $var='IMGD'; $undef++; }
        elsif ($var eq 'CBVW') { $var='IMGD'; $undef++; }
	elsif ($var =~ m/^var\d*$/) { $var='IMGD'; $undef++; } 

# note ECMWF variables may need some conversion factors

	elsif ($var eq 'T') { $var='TMP'; }
	elsif ($var eq 'U') { $var='UGRD'; }
	elsif ($var eq 'V') { $var='VGRD'; }
	elsif ($var eq 'Q') { $var='SPFH'; }
	elsif ($var eq 'R') { $var='RH'; }
	elsif ($var eq '10U') { $var='UGRD'; $lev='10 m above ground'; }
	elsif ($var eq '10V') { $var='VGRD'; $lev='10 m above ground'; }
	elsif ($var eq '2T') { $var='TMP'; $lev='2 m above ground'; }
	elsif ($var eq '2D') { $var='DPT'; $lev='2 m above ground'; }
# old removed 1/2016	elsif ($var eq 'Z') { $var='HGT'; }
	elsif ($var eq 'Z') { $var='GP'; }
	elsif ($var eq 'GH') { $var='HGT'; }
	elsif ($var eq 'E') { $var='IMGD'; $undef++; }
	elsif ($var eq 'SSR') { $var='NSWRS'; $lev='surface'; }
	elsif ($var eq 'SSRD') { $var='DSWRF'; $lev='surface'; }
	elsif ($var eq 'STR') { $var='NLWRS'; $lev='surface'; }
	elsif ($var eq 'STRD') { $var='DLWRF'; $lev='surface'; }
	elsif ($var eq 'TISR') { $var='DSWRF'; $lev='top of atmosphere'; }
	elsif ($var eq 'TSR') { $var='NSWRT'; $lev='top of atmosphere'; }
	elsif ($var eq 'TTR') { $var='ULWRF'; $lev='top of atmosphere'; }
	elsif ($var eq 'SLHF') { $var='LHTFL'; $lev='surface'; }
	elsif ($var eq 'SSHF') { $var='SHTFL'; $lev='surface'; }
	elsif ($var eq 'TP') { $var='APCP'; $lev='surface'; }

        $n=1;
        $byte=0;

	if ($ens ne '') { $ens=":$ens:";  }
        print META "$n:$byte:$date:$var:$lev:$ftime:scale=$dec_scale,$bin_scale:center=$center:subcenter=$subcenter:analysis_or_forecast_process_id=$process:table_3.2=$radius$ens\n";
	$n++;
        $line="";
    }
}
}

1;
