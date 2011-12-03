use v6;
use Test;

use Simple::Redis;
my $r = Simple::Redis.new;
my $host = '127.0.0.1';
my $port = 6379;
$r.connect( $host, $port );

my $e;
my @l;
plan 18;

$r.flushdb();

$r.set( "a", "a" );
$e = $r.append( "a", "b" );
is $e, 2, '1 ok';


$r.append( "a", "cde" );
$e = $r.getrange( "a", 1, 3 );
is $e, 'bcd', '2 ok';

$e = $r.getset( "a", "a" );
is $e, 'abcde', '3 ok';

my $b = "aaa\r\nbbb\r\n";
$r.set( "b", $b );
$e = $r.getset( "b", $b );
is $e, $b, '4 ok';

$r.flushdb();
$e = $r.mset( "a", "a", "b", "b", "c", "c" );
is $e, Bool::True, '5 ok';
$e = $r.get( "a" );
is $e, "a", '6 ok';
$e = $r.get( "b" );
is $e, "b", '7 ok';
$e = $r.get( "c" );
is $e, "c", '8 ok';

@l = $r.mget( "a", "b" );
is @l[0], "a", '9 ok';
is @l[1], "b", '10 ok';

$e = $r.msetnx( "a", "A", "b", "B", "C", "c" );
is $e, 0, '11 ok';
$e = $r.get( "C" );
$e = 0 if !$e;
is $e, 0, '12 ok';

$e = $r.setex( "a", 2, "a" );
is $e, Bool::True, '13 ok';
sleep(3);
$e = $r.get( "a" );
$e = False if !$e;
is $e, Bool::False, '14 ok';

$e = $r.setnx( "b", "b" );
is $e, 0, '15 ok';
$e = $r.setnx( "d", "d" );
is $e, 1, '16 ok';

$e = $r.set( "e", "foo baz baz" );
$e = $r.setrange( "e", 4, "bar" );
is $e, 11, '17 ok';
$e = $r.get( "e" );
is $e, "foo bar baz", '18 ok';

done;

$r.quit();

