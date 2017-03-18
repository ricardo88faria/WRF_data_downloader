package ECMWF::DataServer;

#
# © Copyright 2012-2013 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.
#
use HTTP::Request;
use Data::Dumper;
use Time::HiRes;

my $VERSION = "1.0";
eval "use JSON;";
eval { decode_json("{}"); };

if ($@) {
	warn
"JSON package is missing or does not implement decode_json(). Please install it from CPAN.";

	# Implement a poor-man's JSON serialiser

	sub null  { undef; }
	sub true  { 1; }
	sub false { 0; }

	sub _decode_json {
		my ($x)   = @_;
		my $quote = 0;
		my $back  = 0;
		my @x = split( "", $x );
		foreach my $c (@x) {
			$quote = 1 - $quote if ( $c eq '"' && !$back );
			$c = "=>" if ( $c eq ':' && !$back && !$quote );
			$back = ( $c eq '\\' && !$back );
		}
		$x = join( "", @x );
		my $y = eval $x;
		die "Cannot decode $x" if ($@);
		return $y;
	}

	sub _encode_json {
		my ($x) = @_;
		local ($Data::Dumper::Pair)   = ":";
		local ($Data::Dumper::Indent) = 0;
		local ($Data::Dumper::Useqq)  = 1;
		my $d = Dumper($x);

		# Skip '$VAR1 =' and ';'
		$d = substr( $d, 8, -1 );

		#print "JSON($d)\n";
		return $d;
	}

	*decode_json = \&_decode_json;
	*encode_json = \&_encode_json;
}

sub new {
	my ( $class, @args ) = @_;
	my %args = @args;

	my $self = {};

	my $rc = "$ENV{HOME}/.ecmwfapirc";
	if ( -f $rc ) {
		local ($/);
		open( IN, "<$rc" ) or die "$rc: $!";
		my $m = <IN>;
		close(IN);
		$self = decode_json($m);
	}

	$self->{url} = "https://api.ecmwf.int/v1" unless ( exists $self->{url} );

	$self->{key} = $ENV{"ECMWF_API_KEY"} if ( exists $ENV{"ECMWF_API_KEY"} );
	$self->{url} = $ENV{"ECMWF_API_URL"} if ( exists $ENV{"ECMWF_API_URL"} );
	$self->{email} = $ENV{"ECMWF_API_EMAIL"}
	  if ( exists $ENV{"ECMWF_API_EMAIL"} );

	foreach my $k ( keys %args ) {
		$self->{$k} = $args{$k};
	}

	$self->{offset} = 0;
	$self->{limit}  = 500;
	$self->{status} = "";

	return bless( $self, $class );
}

sub _messages {
	my ( $self, $x ) = @_;
	eval {
		if ( $x->{status} ne $self->{status} )
		{
			$self->{status} = $x->{status};
			put( "Request is ", $x->{status} );
		}
	};
	eval {
		my @m = @{ $x->{messages} };
		foreach my $m (@m) {
			print $m, "\n";
			$self->{offset}++;
		}
	};

}

sub _call {
	my ( $self, $method, $url, $payload ) = @_;

	my $extra = "";
	if ( $method eq "GET" ) {
		$extra = "?offset=$self->{offset}&limit=$self->{limit}";
	}

	## Something is not quite right...
	my $n = 1;
	if ( $url =~ /^https/ && $ENV{HTTPS_PROXY} =~ /ecmwf/ ) { $n = 0; }

	my $ua = ECMWF::UserAgent->new(
		from      => $self->{email},
		timeout   => 60,
		env_proxy => $n
	);
	my $req = HTTP::Request->new( $method, "$url$extra" );

	$req->header(
		"Accept"      => "application/json",
		"X-ECMWF-Key" => $self->{key},
	);

	if ( defined $payload ) {

		if ( ref($payload) ) {
			$payload = encode_json($payload);
		}
		else {

			# For some reason JSON does not encode simple strings
			$payload = encode_json( [$payload] );
			$payload = substr( $payload, 1, -1 );
		}

		$req->content($payload);
		$req->header( "Content-Type" => "application/json", );
	}

	my $try      = 0;
	my $MAXTRIES = 10;
	my $res;

	do {

		my $result = {};

		$res = $ua->request($req);
		if ( $res->is_error ) {
			eval {
				$result = decode_json( $res->content );
				$self->_messages($result);
				print Dumper($result);
			};
			print $res->content if ($@);
			if ( $try++ < $MAXTRIES && $res->code >= 500 ) {
				put("Retrying...");
				sleep(60);
			}
			else {
				die $res->status_line;
			}
		}

	} while ( $res->code >= 500 );

	return if ( $res->code == 204 );

	my $result = decode_json( $res->content );
	die $result->{error} if ( exists $result->{error} );

	$self->_messages($result);
	return $result;
}

sub _execute {
	my ( $self, $url, $request, $target ) = @_;

	my $last;

	put( "ECMWF API perl library ", $VERSION );
	put( "ECMWF API at ",           $self->{url} );
	my $me = $self->_call( "GET", "$self->{url}/who-am-i" );
	my $name = $me->{full_name} ? $me->{full_name} : "'$me->{uid}'";
	put("Welcome $name");

	my $news = $self->_call( "GET", "$self->{url}/$url/news" );
	foreach my $n ( split( "\n", $news->{news} ) ) {
		put($n);
	}

	my $x = $self->_call( "POST", "$self->{url}/$url/requests", $request );

	while ( $x->{code} == 202 ) {
		sleep( $x->{retry} );
		$last = $x->{href};
		$x = $self->_call( "GET", $x->{href} );
	}

	if ( $x->{code} == 303 ) {
		die
		  if (
			$self->_transfer( $x->{href}, $target, $x->{size} ) != $x->{size} );
	}
	else {
		die "Unexpected code: $x->{code}\n";
	}

	$self->_call( "DELETE", $last ) if ($last);
	put("Done");

}

sub retrieve {
	my ( $self, @args ) = @_;
	my %req = @args;
	$self->_execute( "datasets/$req{dataset}", \%req, $req{target} );
}

sub service {
	my ( $self, $service, $request, $target ) = @_;
	$self->_execute( "services/$service", $request, $target );
}

sub _transfer {
	my ( $self, $url, $target, $size ) = @_;

	my $ua = LWP::UserAgent->new(
		keep_alive => 1,
		timeout    => 60,
		env_proxy  => 1,
		from       => $self->{email}
	);

	put( "Tranfering ", bytename($size), " into '", $target, "'" );
	put( "From ",       $url );

	my $try      = 0;
	my $MAXTRIES = 10;
	my $response;
	my $total = 0;

	do {
		my $now = Time::HiRes::time();
		open( OUT, ">$target" ) or die "$target: $!";
		$total = 0;

		$response = $ua->request(
			HTTP::Request->new( GET => $url ),
			sub {
				my $content = shift;
				$total += syswrite( OUT, $content ) or die "$target: $!";
			}
		);

		close(OUT) or die "$target: $!";

		if ( $response->is_error ) {
			if ( $try++ < $MAXTRIES && $response->code >= 500 ) {
				put("Retrying...");
				sleep(60);
			}
			else {
				die $response->status_line;
			}
		}

		my $delta = Time::HiRes::time() - $now;
		if ($delta) {
			put( "Transfer rate ", bytename( $size / $delta ), "/s" );
		}
	} while ( $response->code >= 500 );

	die "Transfer failed: only $total received out of $size"
	  if ( $size != $total );
	return $total;

}

sub nextbytes {
	my ($letter) = @_;
	return "P" if ( $letter eq "T" );
	return "T" if ( $letter eq "G" );
	return "G" if ( $letter eq "M" );
	return "M" if ( $letter eq "K" );
	return "K" if ( $letter eq "b" );
	die "Cannot continue with $letter bytes\n";
}

# Transforms number of bytes onto a divisor of 1024 with proper prefix
sub bytename {
	my ($n) = @_;
	my $l = "b";
	while ( 1024 < $n ) {
		$l = nextbytes($l);
		$n /= 1024;
	}
	$n = sprintf( "%g", $n );
	$l = "" if ( $l eq "b" );
	return "$n ${l}bytes";
}

sub put {
	my (@args) = @_;
	my ( $sec, $min, $hour, $day, $mon, $year ) = localtime;
	my $time = sprintf(
		"%04d-%02d-%02d %02d:%02d:%02d",
		$year + 1900,
		$mon + 1, $day, $hour, $min, $sec
	);
	print $time, " ", @args, "\n";
}

package ECMWF::UserAgent;
use LWP::UserAgent;
use base(LWP::UserAgent);
use Data::Dumper;

sub redirect_ok {
	my ( $self, $prospective_request, $response ) = @_;
	if ( $response->code == 303 ) {
		return 0;
	}
	return 1;
}

1;

