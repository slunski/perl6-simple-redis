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

without_pipelining();

with_pipelining();

justping();

print "String cat: ";
my $time = now;
my $s = '';
for ^10000 { $s ~= "PING\r\n" }
say now - $time;

