use v6;
use Test;

use Simple::Redis;

plan 8;

my $host = '127.0.0.1';
my $port = '6379';

my $re;

my $redis = Simple::Redis.new;

$re = $redis.connect( $host, $port );

say "Info...";
$re = $redis.info();
ok( $re ~~ /\w+/, '1 ok');

say "Set abc";
$re = $redis.set( "t1", "abc" );
is $re, 'Bool::True', '2 ok';

$re = $redis.get( "t1" );
say "Got: $re";
is $re, 'abc', '3 ok';

say "Set 0";
$re = $redis.set( "t2", 0 );
is $re, 'Bool::True', '4 ok';

$re = $redis.get( "t2" );
say "Got: $re";
is $re, 0, '5 ok';

say "Set abcd def";
$re = $redis.set( "t3", "abc def" );
is $re, 'Bool::True', '6 ok';

$re = $redis.get( "t3" );
say "Got: $re";
is $re, "abc def", '7 ok';

say "Flush...";
$redis.flushdb();

$re = $redis.get( "t1" );
say "Empty ?: |$re|";
is $re, '', '8 ok';

$re = $redis.quit();

done;

