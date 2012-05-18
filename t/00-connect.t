use v6;
use Test;

use Simple::Redis;

plan 5;

ok 1, 'Loading module succeeded';

my $host = '127.0.0.1';
my $port = 6379;

my $re;

my $redis = Simple::Redis.new;
#is $redis.defined, Bool::True, '2 ok';
is $redis.defined, Bool::True, '2 ok';

$re = $redis.connect( $host, $port );
is $re, Bool::True, '3 ok';

$re = $redis.ping();
say ">", $re;
is $re, 'PONG', '4 ok';

$re = $redis.quit();
is $re, Bool::True, '5 ok';

done;

