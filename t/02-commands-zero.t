use v6;
use Test;

use Simple::Redis;

plan 8;

my $host = '127.0.0.1';
my $port = 6379;
my $redis = Simple::Redis.new;
$redis.connect( $host, $port );

my $re;

$re = $redis.flushdb();
$re = $redis.set( "t1", "a" );
$re = $redis.set( "t2", "b" );
$re = $redis.set( "t3", "c" );

$re = $redis.dbsize();
is $re, 3, '1 ok';

# Flush db
$re = $redis.flushdb();
is $re, Bool::True, '2 ok';

# Check if realy empty db
$re = $redis.get( "t1" );
ok(!$re.defined, '3 ok');

# Flush all DBs
$re = $redis.set( "db0", "k1" );
#$re->select( 1 );
$re = $redis.set( "db1", "k2" );

$re = $redis.flushall();
is $re, Bool::True, '4 ok';

$re = $redis.get( "db1" );
ok(!$re.defined, '5 ok');

# Other tests
$re = $redis.ping();
is $re, 'PONG', '6 ok';

$re = $redis.set( "t3", "abc def" );
is $re, Bool::True, '7 ok';

$re = $redis.get( "t3" );
is $re, "abc def", '8 ok';

$re = $redis.quit();

done;

