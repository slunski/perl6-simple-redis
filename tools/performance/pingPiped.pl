#!/opt/perl6/bin/perl6 --optimize=3

use Simple::Redis;

my $host = '127.0.0.1';
my $port = 6379;

sub with_pipelining() {
	say 'With pipelining:';

	my $start = now;

	my $r = Simple::Redis.new;
	$r.connect( $host, $port );
	#$r.setMode( PIPELINE );
	$r.setMode( 2 );

	my $c = now;
	say ' * Connect:............', $c - $start;

	for ^10000 { $r.ping() }

	my $b = now;
	say ' * Commands buffering:.', $b - $c, ' / ', $b - $start;

	$r.sendCommands();

	my $s = now;
	say ' * Commands sending:...', $s - $b, ' / ', $s - $start;

	$r.getResponses();
	$r.quit();

	my $a = now;
	my $total = $a - $start;
	say ' * Getting responses:..', $a - $s, ' / ', $total;
	say 'Total: ', $total;
}

with_pipelining();

