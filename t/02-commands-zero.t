use v6;
use Test;

use Simple::Redis;

plan 12;

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

say "Test bgrewriteaof";
$re = $redis.bgrewriteaof();
is $re, 'Bool::True', '3 ok';

say "Test bgsave";
$re = $redis.bgsave();
is $re, 'Bool::True', '4 ok';

$re = $redis.lastsave();
#is $re, /\d+/, '5 ok';
#ok( $re ~~ /^:\d+/, '5 ok');
ok( $re ~~ /\d+/, '5 ok');


# Flush db
say "Flush DB (default: 0)";
$re = $redis.flushdb();
is $re, 'Bool::True', '6 ok';

# Check if realy empty db
$re = $redis.get( "t1" );
is $re, '', '7 ok';


# Flush all DBs
$re = $redis.set( "db0", "k1" );
#$re->select( 1 );
$re = $redis.set( "db1", "k2" );

$re = $redis.flushall();
is $re, 'Bool::True', '8 ok';

my $cat;
#$redis.select( 0 );
$re = $redis.get( "db0" );
$cat = $re; 
#$redis.select( 1 );
$re = $redis.get( "db1" );
$cat ~= $re; 
ok( $cat ~~ '', '9 ok');


# Other tests
$re = $redis.ping();
is $re, 'Bool::True', '10 ok';

say "Set abcd def";
$re = $redis.set( "t3", "abc def" );
is $re, 'Bool::True', '11 ok';

$re = $redis.get( "t3" );
say "Got: $re";
is $re, "abc def", '12 ok';

$re = $redis.quit();

done;

