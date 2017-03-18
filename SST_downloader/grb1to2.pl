#!/usr/bin/perl -w
# 12/7/2009 Public Domain Wesley Ebisuzaki
#
# converts a grib1 to grib2 file using wgrib and wgrib2
#
# for perl beginners
#  \d    matches any digit
#  \d*   matches any number of digits
#  \s    matches any whitespace
#  \S    matches any non-whitespace
#
# phase 1
#
#   make a template file using wgrib2 -new_grid
#
# phase 2
#
#  convert the grib1 file into to a f77 binary file
#  make a metadata file
#     most of the parameters are in the simple inventory but the 
#     scaling is only in the very verbose inventory
#
# phase 3
#     use wgrib2 to read the metadata, template and binary data to 
#     make a grib2 file
#
# v0.99 12/7/2009 Wesley Ebisuzaki release to the public domain
# v0.999 2/2010 Wesley Ebisuzaki
# v0.9999 6/2010 Wesley Ebisuzaki, packing is determined by the script name: 
#             XXXX_cI.pl uses packing cI, support c0, c1, c2, s
# v0.99999 3/2014 support Gaussian, Mercator Spherical, Lambert
#          copy center, subcenter, processid, radius of earth to grib2 out.
#          more portable, use grib12_metadata.pl
#          4/2014 rename grib1to2_v3.pl to grb1to2.pl  (grib1to2 used by other folks)
#                 remove packing selection by name
#                 added -fast option, -ncep_uv option
#                 tmpfiles renamed to $out.*
# V1.0.1 added $undef to keep track of undefined fields
# V1.1 fixed mercator
# V1.3 2/2015 added -gmerge option
# v1.4 12/2015 removed references to $HOME, easier for others to use, no location of template
#
# external programs/scripts/data:
#   grib1to2_metadata.pl     translates wgrib inv -> wgrib2 metadata
#   global_template.g2       grib2 file used as template
#   cnvgrib                  not used (only for uncommon grids)
#   wgrib                    http://www.cpc.ncep.noaa.gov/products/wesley/wgrib.html
#   wgrib2                   http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/
#   smallest_grib2           included with wgrib2
#   gmerge                   included with wgrib2
#
# temp files:
#   $out.bin $out.meta $out.template $out.template.g2
# temp pipes
#   used by slow c0 packing: $out.c1 $out.c2 $out.c3
#   used by fast c0 packing: $out.i.c1 $out.i.c2 $out.i.c3 i=1,2,3
#   used by fast packing:    $out.p1 $out.p2 $out.p3
#

use File::Copy;
use File::Basename;
use POSIX;

# This section needs to be customized

$dir=dirname($0);

require ("$dir/grib1to2_metadata.pl");
$g2_template="$dir/global_template.g2";
$cnvgrib="cnvgrib is missing";
$wgrib="$dir/wgrib";
$wgrib2="$dir/wgrib2";
$smallest_grib2="$dir/smallest_grib2";
$gmerge="$dir/gmerge";
# end of customization

$prog="grb1to2.pl";
$version="v1.5  12/2015 W. Ebisuzaki CPC/NCEP";
$packing = 'c0';
$mk_template = 1;
$fast=0;
$ncep_uv=0;
$conv="fcst";

if ($#ARGV == -1) {
  print "$prog $version\n    grib1to2_metadata.pl version: ";
  grib1to2_metadata_version();
  print "\nconverts grib1 to grib2\n";
  print "$prog [options] INPUT_GRIB1_FILE\n";
  print "options\n";
  print "  -fast                                      fast mode\n";
  print "  -gmerge gmerge_executable                  default=$gmerge\n";
  print "  -grid_template grib2_template              default=N/A bypass grid generation\n";
  print "  -packing [s|c0|c1|c2|c3|j]                 default=$packing   c0=best of c1,c2 and c3\n";
  print "  -o output file                             default=INPUT_GRIB1_FILE.grb2\n";
  print "  -ncep_uv                                   UGRD,VGRD in same grib message\n";
  print "  -smallest_grib2 smallest_grib2_executable  default=$smallest_grib2\n";
  print "  -template grib2_template                   default=$g2_template\n";
  print "  -wgrib wgrib_executable                    default=$wgrib\n";
  print "  -wgrib2 wgrib2_executable                  default=$wgrib2\n";
  print "  -anl          (if ambigous conversion)     default=fcst\n";
  print "\n  preserves center, subcenter, process and shape of earth from grib1 file\n";
  print "  limitation: grid/earth winds determined by first message in grib1 file\n";
  print "  limitation: grid for grib2 is generated from first message in grib1 file\n";
  print "\nex. $prog flux.20140101             flux.20140101 -> flux.20140101.grb2\n    $prog -o flx.grb2 flx.grb       flx.grb -> flx.grb2\n";
  exit 8;
}

$i=0;

for ($i = 0; $i <= $#ARGV; $i++) {
   if ($ARGV[$i] eq '-fast') { $fast = 1 ; }
   elsif ($ARGV[$i] eq '-ncep_uv') { $ncep_uv = 1; }
   elsif ($ARGV[$i] eq '-packing') { $packing = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-cnvgrib') { $cnvgrib = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-gmerge') { $gmerge = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-wgrib') { $wgrib = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-wgrib2') { $wgrib2 = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-smallest_grib2') { $smallest_grib2 = $ARGV[$i+1] ; $i++;}
   elsif ($ARGV[$i] eq '-template') { $g2_template = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-grid_template') { $g2_template = $ARGV[$i+1]; $mk_template = 0; $i++; }
   elsif ($ARGV[$i] eq '-o') { $out = $ARGV[$i+1] ; $i++; }
   elsif ($ARGV[$i] eq '-anl') { $conv = 'anl'; }
   else {
      if ($ARGV[$i] =~ m/^-/) {
          print "Error: unknown option: $ARGV[$i]\n";
          exit 8;
      }
      if (! defined($file)) { $file = $ARGV[$i]; }
      else { 
          print "Error: second input file: $ARGV[$i]\n";
          exit 8;
      }
   }
}


if (! defined($file)) { 
   print "Error: no input file defined\n";
   exit 8;
}
if (! defined($out)) { $out = "$file.grb2"; }

# get a grid defintion

$_=`$wgrib $file -d 1 -V -o /dev/null`;
if (! defined($_) ) {
   print "FATAL ERROR: problem with command: $wgrib $file -d 1 -V -o /dev/null\n";
   exit 8;
}
print "((($_)))\n";


# read metadata from grib1 file .. assume same for all messages
#
if ( /winds\(N\/S\)/ ) { $winds = 'earth'; }
if (/winds\(grid\)/) { $winds = 'grid'; }
if (! defined($winds) ) {
   print "Problem, winds not defined! old $wgrib?\n";
   exit 8;
}

# make a template

if ($mk_template == 0) {
   copy($g2_template, "$out.template");
}
else {
   if (/  latlon: /) {
      / lat  (\S*) to (\S*) by (\S*) /;
      $lat0=$1;
      $lat1=$2;
      $dlat=abs($3);
      if ($lat1 < $lat0) { $dlat = -$dlat; }

      / long (\S*) to (\S*) by (\S*), \((\S*) x (\S*)\)/;
      $lon0=$1;
#     $lon1=$2;
      $dlon=$3;
      $nx =$4;
      $ny =$5;
      system "$wgrib2 -inv /dev/null $g2_template -new_grid_winds $winds -new_grid latlon $lon0:$nx:$dlon $lat0:$ny:$dlat $out.template >/dev/null";
   }

   elsif (/ Lambert Conf: /) {
      / Lat1 (\S*) Lon1 (\S*) Lov (\S*)/;
      $lat1 = $1;
      $lon1 = $2;
      $lov = $3;
      if ($lon1 < 0.0) { $lon1+=360.0; }
      if ($lov < 0.0) { $lov+=360.0; }

      /Latin1 (\S*) Latin2 (\S*) /;
      $latin1 = $1;
      $latin2 = $2;

      / (\S*) Pole \((\S*) x (\S*)\) Dx (\S*) Dy (\S*) /;
      $pole = $1;
      $nx = $2;
      $ny = $3;
      $dx = 1000*$4;
      $dy = 1000*$5;

      if ($pole eq 'North') {
         $lad = $latin1;
         if ($lad < $latin2) { $lad = $latin2; }
      } else {
         $lad = $latin1;
         if ($lad > $latin2) { $lad = $latin2; }
      }

      system "$wgrib2 $g2_template -new_grid_winds $winds -new_grid lambert:$lov:$latin1:$latin2:$lad $lon1:$nx:$dx $lat1:$ny:$dy $out.template >/dev/null";
   }

   elsif (/  gaussian: /) {
      / lat  *(\S*) to  *(\S*)/;
      $lat0=$1;
      $lat1=$2;
      / long (\S*) to (\S*) by (\S*),/;
      $lon0=$1;
      $lon1=$2;
      $dx=$3;
      / \((\S*) x (\S*)\)/;
      $nx=$1;
      $ny=$2;

      system "$wgrib2 $g2_template -new_grid_winds $winds -new_grid gaussian $lon0:$nx:$dx $lat0:$ny $out.template >/dev/null";
   }

   elsif (/  Mercator: /) {
      / long *(\S*) to *(\S*) by (\S*) km/;
      $lon0 = $1;
      $lon1 = $2;
      $dx = $3 * 1000.0;

      / lat  *(\S*) to (\S*) by (\S*) km/;
      $lat0 = $1;
      $lat1 = $2;
      $dy = $3 * 1000.0;
      print "lat: $lat0 $lat1 $dy Mercator \n";

      / \((\S*) x (\S*)\)/;
      $nx=$1;
      $ny=$2;

      / Latin *(\S*)/;
      $latin=$1;

      system "$wgrib2 $g2_template -new_grid_winds $winds -new_grid mercator:$latin $lon0:$nx:$dx:$lon1 $lat0:$ny:$dy:$lat1 $out.template >/dev/null";
   }

   elsif (/ polar stereo: /) {
      / Lat1 *(\S*) *Long1 *(\S*) *Orient *(\S*)/;
      $lat1 = $1;
      $lon1 = $2;
      $lov = $3;
      print "nps: $lat1 $lon1 $lov\n";

      / (\S*) pole \((\S*) x (\S*)\) Dx *(\S*) *Dy *(\S*)/;
      $pole = $1;
      $nx = $2;
      $ny = $3;
      $dx = $4;
      $dy = $5;
      if ($pole eq 'north') { $grid="nps:$lov:60"; }
      else { $grid = "sps:$lov:-60"; }
      system "$wgrib2 $g2_template -new_grid_winds $winds -new_grid $grid $lon1:$nx:$dx $lat1:$ny:$dy $out.template >/dev/null";
   }
   else {
      print "Error: unsupported grid\n";
      exit 8;

      # extract first record
      system "$wgrib $file -d 1 -grib -o $out.template.g1 >/dev/null";

      # convert record to grib2
      system "$cnvgrib -g12 -nv -p0 $out.template.g1 $out.template.g2";

      # new grib2 file with data=0 and clean pdt
      system "$wgrib2 $out.template.g2 -rpn 0 -set_pdt 0 -grib_out $out.template >/dev/null";

      unlink "$out.template.g1";
      unlink "$out.template.g2";
   }
}

$undef = 0;
grib2_metadata($file,$out);

# this line makes the grib2 file
# right now 3 versions of the grib file are made using different complex packing
# later a script will combine the files into a optimal complex packed file

if ($ncep_uv == 1) { 
      mkfifo("$out.uv",0600) or die "mkfifo failed";
}

if ($packing eq 'c0') {

   if ($fast == 0) {
      mkfifo("$out.c11",0600) or die "mkfifo failed";
      mkfifo("$out.c12",0600) or die "mkfifo failed";
      mkfifo("$out.c13",0600) or die "mkfifo failed";
      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type c1 -grib_out $out.c11 -set_grib_type c2 -grib_out $out.c12 -set_grib_type c3 -grib_out $out.c13 -inv /dev/null &";

      if ($ncep_uv == 0) {
         system "$smallest_grib2 $out $out.c11 $out.c12 $out.c13";
      }
      else {
         system "$smallest_grib2 $out.uv $out.c11 $out.c12 $out.c13 &";
         system "$wgrib2 $out.uv -ncep_uv $out -inv /dev/null";
      }

      unlink "$out.c11";
      unlink "$out.c12";
      unlink "$out.c13";
   }
   else {
      mkfifo("$out.1.c1",0600) or die "mkfifo failed";
      mkfifo("$out.1.c2",0600) or die "mkfifo failed";
      mkfifo("$out.1.c3",0600) or die "mkfifo failed";
      mkfifo("$out.2.c1",0600) or die "mkfifo failed";
      mkfifo("$out.2.c2",0600) or die "mkfifo failed";
      mkfifo("$out.2.c3",0600) or die "mkfifo failed";
      mkfifo("$out.3.c1",0600) or die "mkfifo failed";
      mkfifo("$out.3.c2",0600) or die "mkfifo failed";
      mkfifo("$out.3.c3",0600) or die "mkfifo failed";
      mkfifo("$out.p1",0600) or die "mkfifo failed";
      mkfifo("$out.p2",0600) or die "mkfifo failed";
      mkfifo("$out.p3",0600) or die "mkfifo failed";

      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -if_n 1::3 -set_grib_type c1 -grib_out $out.1.c1 -if_n 1::3 -set_grib_type c2 -grib_out $out.1.c2 -if_n 1::3 -set_grib_type c3 -grib_out $out.1.c3 -inv /dev/null &";

      system "$smallest_grib2 $out.p1 $out.1.c1 $out.1.c2 $out.1.c3 >/dev/null &";

      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -if_n 2::3 -set_grib_type c1 -grib_out $out.2.c1 -if_n 2::3 -set_grib_type c2 -grib_out $out.2.c2 -if_n 2::3 -set_grib_type c3 -grib_out $out.2.c3 -inv /dev/null &";

      system "$smallest_grib2 $out.p2 $out.2.c1 $out.2.c2 $out.2.c3 >/dev/null &";

      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -if_n 3::3 -set_grib_type c1 -grib_out $out.3.c1 -if_n 3::3 -set_grib_type c2 -grib_out $out.3.c2 -if_n 3::3 -set_grib_type c3 -grib_out $out.3.c3 -inv /dev/null &";

      system "$smallest_grib2 $out.p3 $out.3.c1 $out.3.c2 $out.3.c3 >/dev/null &";

      if ($ncep_uv == 0) {
         system "$gmerge $out $out.p1 $out.p2 $out.p3";
      }
      else {
         system "$gmerge $out.uv $out.p1 $out.p2 $out.p3 &";
         system "$wgrib2 $out.uv -ncep_uv $out -inv /dev/null";
      }

      unlink "$out.1.c1";
      unlink "$out.1.c2";
      unlink "$out.1.c3";
      unlink "$out.2.c1";
      unlink "$out.2.c2";
      unlink "$out.2.c3";
      unlink "$out.3.c1";
      unlink "$out.3.c2";
      unlink "$out.3.c3";
      unlink "$out.p1";
      unlink "$out.p2";
      unlink "$out.p3";

   }
}
else {
#  packing != c0
   if ($fast == 0) {
      if ($ncep_uv == 0) {
         system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type $packing -s -grib_out $out";
      }
      else {
        system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type $packing -inv /dev/null -grib_out - | $wgrib2 - -ncep_uv $out ";
      }
   }
   else {
      mkfifo("$out.p1",0600) or die "mkfifo failed";
      mkfifo("$out.p2",0600) or die "mkfifo failed";
      mkfifo("$out.p3",0600) or die "mkfifo failed";
      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type $packing -if_n 1::3 -grib_out $out.p1 -inv /dev/null &";
      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type $packing -if_n 2::3 -grib_out $out.p2 -inv /dev/null &";
      system "$wgrib2 <$out.meta -order raw $out.template -i -import_bin $out.bin -set_metadata $out.meta -header -set_grib_type $packing -if_n 3::3 -grib_out $out.p3 -inv /dev/null &";

      if ($ncep_uv == 0) {
         system "$gmerge $out $out.p1 $out.p2 $out.p3";
      }
      else {
         system "$gmerge $out.uv $out.p1 $out.p2 $out.p3 &";
         system "$wgrib2 $out.uv -ncep_uv $out -inv /dev/null";
      }
   
      unlink "$out.p1";
      unlink "$out.p2";
      unlink "$out.p3";

   }

}


print "remove files\n";
unlink "$out.template";
unlink "$out.bin";
unlink "$out.meta";
if ($ncep_uv == 1) { unlink "$out.uv"; }
print "$undef fields with unknown grib2 names set to IMGD\n";