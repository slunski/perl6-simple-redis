use v6;
use Test;

use Simple::Redis;

plan 11;

my $host = '127.0.0.1';
my $port = 6379;

my $re;

my $redis = Simple::Redis.new;

$re = $redis.connect( $host, $port );

$redis.flushdb();

$re = $redis.info();
ok( $re ~~ /\w+/, '1 ok');

$re = $redis.set( "t1", "abc" );
is $re, Bool::True, '2 ok';

$re = $redis.get( "t1" );
is $re, 'abc', '3 ok';

$re = $redis.set( "t2", 0 );
is $re, Bool::True, '4 ok';

$re = $redis.get( "t2" );
is $re, 0, '5 ok';

$re = $redis.set( "t3", "abc def" );
is $re, Bool::True, '6 ok';

$re = $redis.get( "t3" );
is $re, "abc def", '7 ok';

$redis.flushdb();

$re = $redis.get( "t1" );
ok(!$re.defined, '8 ok');

$re = $redis.set( 3, "c" );
is $re, Bool::True, '9 ok';

$re = $redis.get( 3 );
is $re, 'c', '10 ok';

my $b = "aaa\r\nbbb\r\n";
$redis.set( "b", $b );
$re = $redis.get( "b" );
is $re, $b, '11 ok';


$re = $redis.quit();

done;

