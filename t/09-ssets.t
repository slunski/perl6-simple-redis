use v6;
use Test;

use Simple::Redis;
my $host = '127.0.0.1';
my $port = 6379;
my $r = Simple::Redis.new;
$r.connect( $host, $port );

my $e;
my @l;
$r.flushall();

plan 21;


$e = $r.zadd( "ss", 1, "a" );
is $e, 1, '1 ok';
$e = $r.zadd( "ss", 2, "b" );
is $e, 1, '2 ok';

$e = $r.zcard( "ss" );
is $e, 2, '3 ok';

$r.zadd( "ss", 1, "c" );
$r.zadd( "ss", 1, "d" );
$e = $r.zcount( "ss", 1, 1 );
is $e, 3, '4 ok';

$e = $r.zincrby( "ss", 2, "c"  );
is $e, 3, '5 ok';

$r.zadd( "ss2", 1, "a" );
$r.zadd( "ss2", 1, "c" );
$e = $r.zinterstore( "ss3", 2, "ss", "ss2", "WEIGHTS", 2, 3 );
is $e, 2, '6 ok';

@l = $r.zrange( "ss", 1, 2  );
is @l[0], 'd', '7 ok';

@l = $r.zrangebyscore( "ss", "(1", "+inf" );
is @l[0], 'b', '8 ok';

$e = $r.zrank( "ss", "c"  );
is $e, 3, '9 ok';
$e = $r.zrank( "ss", "e"  );
is $e.defined, False, '10 ok';

$e = $r.zrem( "ss", "b" );
is $e, 1, '11 ok';

$e = $r.zremrangebyrank( "ss", 0, 1  );
is $e, 2, '12 ok';

$r.flushdb();
$r.zadd( "ss", 1, "a" );
$r.zadd( "ss", 2, "b" );
$r.zadd( "ss", 3, "c" );
$r.zadd( "ss", 4, "d" );
$r.zadd( "ss", 5, "e" );
$r.zadd( "ss", 6, "f" );
$r.zadd( "ss", 7, "g" );
$e = $r.zremrangebyscore( "ss", 2, 4 );
is $e, 3, '13 ok';

$r.flushdb();
$r.zadd( "ss", 1, "a" );
$r.zadd( "ss", 2, "b" );
$r.zadd( "ss", 3, "c" );
$r.zadd( "ss", 4, "d" );
$r.zadd( "ss", 5, "e" );
$r.zadd( "ss", 6, "f" );
$r.zadd( "ss", 7, "g" );
@l = $r.zrevrange( "ss", 1, 3  );
is @l[0], 'f', '14 ok';
is @l[1], 'e', '15 ok';

$r.flushdb();
$r.zadd( "ss", 1, "a" );
$r.zadd( "ss", 2, "b" );
$r.zadd( "ss", 3, "c" );
$r.zadd( "ss", 4, "d" );
$r.zadd( "ss", 5, "e" );
$r.zadd( "ss", 6, "f" );
$r.zadd( "ss", 7, "g" );
@l = $r.zrevrangebyscore( "ss", 3, 1 );
is @l[0], 'c', '16 ok';
is @l[1], 'b', '17 ok';
is @l[2], 'a', '18 ok';

$e = $r.zrevrank( "ss", "c" );
is $e, 4, '19 ok';

$e = $r.zscore( "ss", 'c' );
is $e, 3, '20 ok';

$r.zadd( "ss2", 1, "h" );
$r.zadd( "ss2", 2, "i" );
$r.zadd( "ss2", 3, "j" );
$e = $r.zunionstore( "ss3", 2, "ss", "ss2", "WEIGHTS", 2, 3 );
is $e, 10, '21 ok';

done;

$r.quit();

