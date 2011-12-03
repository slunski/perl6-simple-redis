use v6;
use Test;

use Simple::Redis;

my $host = '127.0.0.1';
my $port = 6379;

my $r = Simple::Redis.new;
$r.connect( $host, $port );

plan 17;

my $e;

$r.flushdb();
$e = $r.sadd( "let", "a" );
is $e, 1, '1 ok';

$r.set( "a", "a" );
$e = $r.sadd( "a", "a" );
is $e, False, '2 ok';

$r.sadd( "let", "b" );
$e = $r.scard( "let" );
is $e, 2, '3 ok';

my @l;
$r.sadd( "let", "c" );
$r.sadd( "let", "d" );
$r.sadd( "let2", "b" );
$r.sadd( "let2", "c" );
@l = $r.sdiff( "let", "let2" );
is @l[0], 'd', '4 ok';
is @l[1], 'a', '5 ok';

$e = $r.sdiffstore( "let3", "let", "let2" );
is $e, 2, '6 ok';

@l = $r.sinter( "let", "let2" );
is @l[0], 'c', '7 ok';
is @l[1], 'b', '8 ok';

$e = $r.sinterstore( "let3", "let", "let2" );
is $e, 2, '9 ok';

$e = $r.sismember( "let", "e" );
is $e, 0, '10 ok';
$e = $r.sismember( "let", "a" );
is $e, 1, '11 ok';

@l = $r.smembers( "let2" );
is @l[0], 'c', '12 ok';
is @l[1], 'b', '13 ok';

$e = $r.smove( "let", "let2", "a" );
is $e, 1, '14 ok';
$e = $r.sismember( "let", "a" );
is $e, 0, '15 ok';
$e = $r.sismember( "let2", "a" );
is $e, 1, '16 ok';

$e = $r.spop( "let" );
is $e.defined, True, '17 ok';


exit;
$e = $r.srandmember( "lst" );
$e = $r.srem( "lst" );
$e = $r.sunion( "lst" );
$e = $r.sunionstore( "lst" );


is $e, Bool::True, '3 ok';


done;

$e = $r.quit();

