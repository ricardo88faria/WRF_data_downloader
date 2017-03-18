#!/usr/bin/env perl

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }

use ECMWF::DataServer;

my $client = ECMWF::DataServer->new();

$client->retrieve(
	dataset => "interim",
	step    => "0",
#	number  => "all",
	levtype => "sfc",
	date    => "20110501/to/20110701",
	time    => "00/06/12/18",
#	origin  => "all",
	type    => "an",
	param   => "172/134/151/165/166/167/168/169/235/33/34/31/141/139/170/183/236/39/40/41/42",
#	area    => "70/-130/30/-60",
	grid    => "128",
	target  => "ERA-Int_sfc_.grib",
);
