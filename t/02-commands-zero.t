use v6;
use Test;

use Simple::Redis;

plan 13;

my $host = '127.0.0.1';
my $port = '6379';
my $redis = Simple::Redis.new;
$re = $redis.connect( $host, $port );

my $re;

$re = $redis.set( "t1", "a" );
$re = $redis.set( "t2", "b" );
$re = $redis.set( "t3", "c" );

$re = $redis.dbsize();
is $re, 3, '1 ok';

# Save methods
$re = $redis.save();
is $re, 'Bool::True', '2 ok';

$re = $redis.bgrewriteaof();
is $re, 'Bool::True', '3 ok';

$re = $redis.bgsave();
is $re, 'Bool::True', '4 ok';

$re = $redis.lastsave();
#is $re, /\d+/, '5 ok';
#ok( $re ~~ /^:\d+/, '5 ok');
ok( $re ~~ /\d+/, '5 ok');


# Flush db
$re = $redis.flushdb();
is $re, 'Bool::True', '6 ok';

# Check if realy empty db
$re = $redis.get( "t1" );
is $re, Any, '7 ok';


# Flush all DBs
$re = $redis.set( "db0", "k1" );
#$re->select( 1 );
$re = $redis.set( "db1", "k2" );

$re = $redis.flushall();
is $re, 'Bool::True', '8 ok';

$redis.select( 0 );
$re = $redis.get( "db0" );
is $re, Any, '9 ok';
$redis.select( 1 );
$re = $redis.get( "db1" );
is $re, Any, '10 ok';


# Other tests
$re = $redis.ping();
is $re, 'Bool::True', '11 ok';

$re = $redis.set( "t3", "abc def" );
is $re, 'Bool::True', '12 ok';

$re = $redis.get( "t3" );
say "Got: $re";
is $re, "abc def", '13 ok';

$re = $redis.quit();

done;

