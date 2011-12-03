use v6;
use Test;

use Simple::Redis;

plan 13;

my $host = '127.0.0.1';
my $port = 6379;

my $re;

my $redis = Simple::Redis.new or die();
$re = $redis.connect( $host, $port ) or die();


# Error message test, should detect too much params
$re = $redis.decrby( "e", "r", "r", "o", "r" );
my $e = $redis.errormsg();
is $e, 'Bad parameters count', '1 ok';


$redis.set( "a", 0 );
$redis.set( "b", 1 );
$redis.set( "c", 2 );
$redis.set( "d", 3 );
$redis.set( "e", 4 );
$redis.set( "f", 5 );
$redis.set( "g", 6 );
$redis.set( "h", 7 );

$re = $redis.del( "a", "b", "c", "d", "e", "f", "g", "h" );
#say $redis.errormsg();
is $re, 8, '2 ok';


$redis.set( "d", 3 );
$re = $redis.decrby( "d", 2 );
$re = $redis.get( "d" );
is $re, 1, '3 ok';


$re = $redis.expire( "d", 20 );
is $re, 1, '4 ok';
sleep 1;
$re = $redis.ttl( "d" );
ok( $re < 20, '5 ok');

$redis.del( "a" );

$re = $redis.expire( "a", 20 );
is $re, 0, '6 ok';
$re = $redis.ttl( "a" );
is $re, -1, '7 ok';


$re = $redis.setbit( "a", 2, 1 );
is $re, 0, '8 ok';
$re = $redis.setbit( "a", 2, 1 );
is $re, 1, '9 ok';
$re = $redis.getbit( "a", 2 );
is $re, 1, '10 ok';


$redis.set( "a", "Hallo World!" );
$re = $redis.getrange( "a", 0, 2 );
#say $redis.errormsg;
is $re, 'Hal', '11 ok';


$redis.set( "a", 0 );
$redis.set( "b", 1 );
$redis.set( "c", 2 );
$redis.set( "d", 3 );
say "12. mget test";
my @m = $redis.mget( "a", "b", "c", "d" );
is @m.elems, 4, '12 ok';

@m = $redis.mget( "a" );
is @m.elems, 1, '13 ok';

$re = $redis.quit();

done;

