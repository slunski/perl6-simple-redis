#!/usr/bin/perl6
#!/opt/perl6/bin/perl6

use Simple::Redis;

my $host = '127.0.0.1';
my $port = 6379;

sub without_pipelining() {
	print 'Without pipelining:....';

	my $start = now;

	my $r = Simple::Redis.new;
	$r.connect( $host, $port );

	for ^10000 { $r.ping() }

	$r.quit();

	my $end = now;

	say $end - $start;
}

sub with_pipelining() {
	say 'With pipelining:';

	my $start = now;

	my $r = Simple::Redis.new;
	$r.connect( $host, $port );
	$r.setMode( 'PIPE' );

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


print "String cat: ";
my $time = now;
my $s = '';
for ^10000 { $s ~= "PING\r\n" }
say now - $time;


# Rakudo Star 2011.07
#$ ./tools/performance/pipelinedPings.pl 
#Without pipelining:....75.4538171536286
#With pipelining:
# * Connect:............0.0354745925215724
# * Commands buffering:.39.6002109704641 / 39.6356858846918
# * Commands sending:...0.0830696202531646 / 39.7187552565181
# * Getting responses:..0.0718294051627385 / 39.7905844155844
#Total: 39.7905844155844
#String cat: 3.48614741244119

#$ ./tools/performance/pipelinedPings.pl 
#Without pipelining:....84.6846965699208
#With pipelining:
# * Connect:............0.0408542246982358
# * Commands buffering:.39.1653005464481 / 39.2061538461538
# * Commands sending:...0.0572878897751994 / 39.2634428004331
# * Getting responses:..0.0628099173553719 / 39.3262518968134
#Total: 39.3262518968134
#String cat: 3.3853305785124

# Rakudo dated 24.11.2011
#Without pipelining:....10.5984200892474
#With pipelining:
# * Connect:............0.00936160387592535
# * Commands buffering:.7.03981944359148 / 7.0491810474674
# * Commands sending:...0.00760651629072682 / 7.05678756375813
# * Getting responses:..0.00932539682539683 / 7.06611296058353
#Total: 7.06611296058353
#String cat: 0.326384379421613

