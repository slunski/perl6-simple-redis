use v6;
use Test;

use Simple::Redis;
use Simple::Redis::Admin;

plan 6;

my $host = '127.0.0.1';
my $port = 6379;
my $redis = Simple::Redis::Admin.new;
$redis.connect( $host, $port );

my $re;

$re = $redis.flushdb();
$re = $redis.set( "t1", "a" );
$re = $redis.set( "t2", "b" );
$re = $redis.set( "t3", "c" );

$re = $redis.save();
is $re, Bool::True, '1 ok';

sleep(1);
$re = $redis.bgrewriteaof();
is $re, Bool::True, '2 ok';

sleep(1);
$re = $redis.lastsave();
ok( $re ~~ /\d+/, '3 ok');

sleep 1;

$re = $redis.bgsave();
is $re, Bool::True, '4 ok';


$re = $redis.config( "get", "save" );
ok( $re ~~ /\S+/, '5 ok');

$re = $redis.config( "set", "save", 900, 1, 300, 10 );
ok( $re ~~ /\S+/, '6 ok');

$re = $redis.quit();

done;

