use v6;
use Test;

use Simple::Redis;
my $r = Simple::Redis.new;
my $host = '127.0.0.1';
my $port = '6379';
$r.connect( $host, $port );

my $e;
my @l;
plan 5;

$r.flushdb();

$r.set( "a", "a" );
$e = $r.append( "a", "b" );
is $e, 2, '1 ok';


$r.append( "a", "cde" );
$e = $r.getrange( "a", 1, 3 );
is $e, 'bcd', '2 ok';

$e = $r.getset( "a", "a" );
is $e, 'abcde', '3 ok';

$e = $r.mset( "a", "a", "b", "b", "c", "c" );
is $e, Bool::True, '4 ok';
$e = $r.get( "a" );
is $e, "a", '5 ok';
$e = $r.get( "b" );
is $e, "b", '6 ok';
$e = $r.get( "c" );
is $e, "c", '7 ok';

@l = $r.mget( "a", "b" );
is @l[0], "a", '8 ok';
is @l[1], "b", '9 ok';

$e = $r.msetnx( "a", "A", "b", "B", "C", "c" );
is $e, 1, '10 ok';
$e = $r.get( "C" );
is $e, 1, '11 ok';

exit;

$e = $r.setex( );
is $e, , '3 ok';

$e = $r.setnx( );
is $e, , '3 ok';

$e = $r.setrange( );
is $e, , '3 ok';







$r.quit();

done;

