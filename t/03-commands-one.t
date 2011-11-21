use v6;
use Test;

use Simple::Redis;

# expire command is NIY
#plan 10;
plan 8;

my $host = '127.0.0.1';
my $port = '6379';
my $redis = Simple::Redis.new;
my $re;

$re = $redis.connect( $host, $port ) or die();

#$re = $redis.auth( "secret" );
$re = True;
is $re, True, '1 ok';

$re = $redis.set( "a", "2" );
$re = $redis.decr( "a" );
is $re, 1, '2 ok';

$re = $redis.echo( "abc def");
is $re, 'abc def', '3 ok';

$re = $redis.exists( "a" );
is $re, 1, '4 ok';

$re = $redis.set( "b", "2" );
$re = $redis.incr( "b" );
is $re, 3, '5 ok';

$redis.set( "c", "3" );
$redis.select( 1 );
$redis.set( "c", "5" );
$redis.select( 0 );
$re = $redis.get( "c" );
is $re, 3, '6 ok';

$redis.set( "d", "abcdefghij" );
$re = $redis.strlen( "d" );
is $re, 10, '7 ok';


$redis.set( "e", "ace" );
$re = $redis.type( "e" );
is $re, 'string', '8 ok';


#say "Expiration";
#$re = $redis.persist();
#is $re, 'Bool::True', '6 ok';
#$re = $redis.ttl( "a" );
#is $re, ':-1', '9 ok';
#$re = $redis.expire( "a", 11 );
#$re = $redis.ttl();
#$s $re, 11, '10 ok';


$re = $redis.quit();

done;
