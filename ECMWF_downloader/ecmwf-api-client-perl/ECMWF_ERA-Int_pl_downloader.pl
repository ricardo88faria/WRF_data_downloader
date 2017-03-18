#!/usr/bin/env perl

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }

use ECMWF::DataServer;

my $client = ECMWF::DataServer->new();

$client->retrieve(
	dataset => "interim",
	step    => "0",
#	number  => "all",
	levtype => "pl",
	levelist=> "all",
	date    => "20110501/to/20110701",
	time    => "00/06/12/18",
#	origin  => "all",
	type    => "an",
	param   => "129/130/131/132/157",
#	area    => "70/-130/30/-60",
	grid    => "128",
	target  => "ERA-Int_pl_.grib",
);
