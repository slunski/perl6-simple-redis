#!/opt/perl6/bin/perl6 --optimize=3

use Simple::Redis;

my $host = '127.0.0.1';
my $port = 6379;

sub justping() {
	print 'Just ping:.............';

	my $start = now;

	my $r = Simple::Redis.new;
	$r.connect( $host, $port );

	for ^10000 { $r.justping() }

	$r.quit();

	my $end = now;

	say $end - $start;
}

justping();


