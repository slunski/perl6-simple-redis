use v6;
use Test;

use Simple::Redis;

plan 7;

my $host = '127.0.0.1';
my $port = 6379;

my $re;

my $redis = Simple::Redis.new or die();
$re = $redis.connect( $host, $port ) or die();


# Error message
$re = $redis.decrby( "e", "r", "r", "o", "r" );
my $e = $redis.errormsg();
say "Error is OK here: $e";
ok( $e ~~ /^\-ERR/,  '1 ok' );


$redis.set( "a", 0 );
$redis.set( "b", 1 );
$redis.set( "c", 2 );
$redis.set( "d", 3 );
$redis.set( "e", 4 );
$redis.set( "f", 5 );
$redis.set( "g", 6 );
$redis.set( "h", 7 );

$re = $redis.del( "a", "b", "c", "d", "e", "f", "g", "h" );
is $re, 8, '2 ok';

$redis.set( "d", 3 );
$re = $redis.decrby( "d", 2 );
$re = $redis.get( "d" );
is $re, 1, '3 ok';

$re = $redis.expire( "d", 20 );
$re = $redis.ttl( "d" );
is $re, 20, '4 ok';


$redis.del( "a" );
$re = $redis.setbit( "a", 2, 1 );
is $re, 0, '5 ok';
$re = $redis.setbit( "a", 2, 1 );
is $re, 1, '6 ok';
$re = $redis.getbit( "a", 2 );
is $re, 1, '7 ok';


#$redis.set( "a", "Hallo World!" );
#$re = $redis.getrange( "a", 0, 2 );
#say $redis.error;
#is $re, 'Hal', '8 ok';







$re = $redis.quit();

done;

