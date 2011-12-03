use v6;
use Test;

use Simple::Redis;

plan 32;

my $host = '127.0.0.1';
my $port = 6379;
my $e;
my @l;

my $r = Simple::Redis.new;
$r.connect( $host, $port );
$r.flushdb();


$e = $r.lpush( "lst", "a" );
is $e, 1, '1 ok';

$e = $r.lpop( "lst" );
is $e, 'a', '2 ok';

$e = $r.lpushx( "lst2", "b" );
is $e, 0, '3 ok';
$r.lpush( "lst", "a" );
$e = $r.lpushx( "lst", "b" );
is $e, 2, '4 ok';


$e = $r.linsert( "lst", "AFTER", "b", "c" );
is $e, 3, '5 ok';
$e = $r.lpop( "lst" );
$e = $r.lpop( "lst" );
is $e, 'c', '6 ok';


$e = $r.lset( "lst", 0, "d" );
$e = $r.lpop( "lst" );
is $e, 'd', '7 ok';


$r.flushdb();
$r.lpush( "lst", "c" );
$r.lpush( "lst", "b" );
$r.lpush( "lst", "a" );
$e = $r.llen( "lst" );
is $e, 3, '8 ok';

$e = $r.lindex( "lst", 1 );
is $e, "b", '9 ok';


$r.lpush( "lst", "c" );
$r.lpush( "lst", "b" );
$e = $r.lrem( "lst", 0, "c" );
is $e, 2, '10 ok';


@l = $r.lrange( "lst", 0, -1 );
is @l.elems, 3, '11 ok';


$r.lpush( "lst", "c" );
$r.lpush( "lst", "a" );
$e = $r.ltrim( "lst", 1, -1 );
is $e, Bool::True, '12 ok';
$e = $r.lpop( "lst" );
is $e, 'c', '13 ok';


my $len = $r.llen( "lst" );
$e = $r.rpush( "lst", "d" );
is $e, $len + 1, '14 ok';


$e = $r.rpop( "lst" );
is $e, 'd', '15 ok';
$e = $r.llen( "lst" );
is $e, $len, '16 ok';


$e = $r.rpushx( "lst2", "d" );
is $e, 0, '17 ok';
$e = $r.rpushx( "lst", "d" );
is $e, $len + 1, '14 ok';
$e = $r.rpop( "lst" );
is $e, 'd', '19 ok';
$e = $r.llen( "lst" );
is $e, $len, '20 ok';


$r.flushdb();
$r.lpush( "lst", "c" );
$r.lpush( "lst", "b" );
$r.lpush( "lst", "a" );
$e = $r.rpoplpush( "lst", "lst2" );
is $e, 'c', '21 ok';
$r.lpop( "lst2" );
is $e, 'c', '22 ok';



$r.flushdb();
$r.lpush( "lst", "c" );
$r.lpush( "lst", "b" );
$r.lpush( "lst", "a" );
$r.lpush( "lst2", "a" );
@l = $r.blpop( "lst2", "lst", 1 );
is @l[0], 'lst2', '23 ok';
is @l[1], 'a', '24 ok';
@l = $r.blpop( "lst2", "lst", 1 );
is @l[0], 'lst', '25 ok';
is @l[1], 'a', '26 ok';


$r.lpush( "lst2", "b" );
$r.lpush( "lst2", "a" );
@l = $r.brpop( "lst2", "lst", 1 );
is @l[0], 'lst2', '27 ok';
is @l[1], 'b', '28 ok';
$r.lpop( "lst2" );
@l = $r.brpop( "lst2", "lst", 1 );
is @l[0], 'lst', '29 ok';
is @l[1], 'c', '30 ok';


$e = $r.brpoplpush( "lst", "lst2", 1 );
is $e, 'b', '31 ok';
$e = $r.lpop( "lst2" );
is $e, 'b', '32 ok';



$r.quit();

done;

