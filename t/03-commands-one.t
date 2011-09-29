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

say "SKIP: Auth";
# Password protected server needed so skip
#$re = $redis.auth( "secret" );
is 1, 1, '1 ok';

say "Decr";
$re = $redis.set( "a", "2" );
$re = $redis.decr( "a" );
is $re, 1, '2 ok';

say "Echo";
$re = $redis.echo( "abc def");
is $re, 'abc def', '3 ok';

say "Exists";
$re = $redis.exists( "a" );
is $re, 1, '4 ok';

say "Incr";
$re = $redis.set( "b", "2" );
$re = $redis.incr( "b" );
is $re, 3, '5 ok';

say "Select";
$redis.set( "c", "3" );
$redis.select( 1 );
$redis.set( "c", "5" );
$redis.select( 0 );
$re = $redis.get( "c" );
is $re, 3, '6 ok';

say "Strlen";
$redis.set( "d", "abcdefghij" );
$re = $redis.strlen( "d" );
is $re, 10, '7 ok';


say "Type";
$redis.set( "e", "ace" );
$re = $redis.type( "e" );
is $re, 'string', '8 ok';


say "Expiration";
#$re = $redis.persist();
#is $re, 'Bool::True', '6 ok';
#$re = $redis.ttl( "a" );
#is $re, ':-1', '9 ok';
#$re = $redis.expire( "a", 11 );
#$re = $redis.ttl();
#$s $re, 11, '10 ok';


$re = $redis.quit();

done;
