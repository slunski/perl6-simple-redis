#!/opt/perl6/bin/perl6 --optimize=3

use Simple::Redis;

my $host = '127.0.0.1';
my $port = 6379;

sub without_pipelining() {
	print 'Without pipelining:....';

	my $start = now;

	my $r = Simple::Redis.new or die;
	$r.connect( $host, $port );

	for ^10000 { $r.ping() }

	$r.quit();

	my $end = now;

	say $end - $start;
}

without_pipelining();


