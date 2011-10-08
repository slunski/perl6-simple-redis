use v6;
use Test;

use Simple::Redis;

my $host = '127.0.0.1';
my $port = '6379';

plan 22;

my $e;
my $r = Simple::Redis.new;

$r.connect( $host, $port ) or die();
$r.flushdb();


# New field
$e = $r.hset( "hsh", "a", 1 );
is $e, 1, '1 ok';
# Existing field
$e = $r.hset( "hsh", "a", 2 );
is $e, 0, '2 ok';

$e = $r.hget( "hsh", "a" );
is $e, 2, '3 ok';
$e = $r.hget( "hsh", "b" );
is $e, Any, '4 ok';

$e = $r.hmset( "hsh" );
is $e, Bool::False, '5 ok';
$e = $r.hmset( "hsh", "b", 2, "c", 3 );
is $e, Bool::True, '6 ok';

$e = $r.hsetnx( "hsh", "d", 4,  );
is $e, 1, '7 ok';
$e = $r.hsetnx( "hsh", "d", 5,  );
is $e, 0, '8 ok';
$e = $r.hget( "hsh", "d" );
is $e, 4, '9 ok';

$e = $r.hdel( "hsh", "d" );
is $e, 1, '10 ok';
$e = $r.hget( "hsh", "d" );
is $e, Any, '11 ok';

$e = $r.hexists( "hsh", "a" );
is $e, 1, '12 ok';
$e = $r.hexists( "hsh", "d" );
is $e, 0, '13 ok';

$r.flushdb();
$e = $r.hset( "hsh", "a", 1 );
$e = $r.hset( "hsh", "b", 2 );
my @l = $r.hgetall( "hsh" );
is @l.elems, 4, '14 ok';

$e = $r.hincrby( "hsh", "a", 2 );
$e = $r.hget( "hsh", "a" );
is $e, 3, '15 ok';

@l = $r.hkeys( "hsh" );
is @l.elems, 2, '16 ok';


$e = $r.hlen( "hsh" );
is $e, 2, '17 ok';

$r.flushdb();
$e = $r.hset( "hsh", "a", 1 );
$e = $r.hset( "hsh", "b", 2 );
$e = $r.hset( "hsh", "c", 3 );
@l = $r.hmget( "hsh", "a", "b" );
is @l.elems, 2, '18 ok';
$e = $r.hmget( "hsh", "a", "d", "b" );
is @l.elems, 2, '19 ok';


$r.flushdb();
$e = $r.hset( "hsh", "a", 1 );
$e = $r.hset( "hsh", "b", 2 );
$e = $r.hset( "hsh", "c", 3 );
@l = $r.hvals( "hsh" );
is @l.elems, 3, '20 ok';

my @h;
my $a = "abc\r\ndef";
$r.hset( "hsh", "d", $a );
@h = $r.hmget( "hsh", "d" );
is @h[0], $a, '21 ok';

my $b = "abc\r\ndef\r\n";
$r.hset( "hsh", "e", $b );
@h = $r.hmget( "hsh", "e" );
is @h[0], $b, '22 ok';


$e = $r.quit();

done;

