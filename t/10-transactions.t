use v6;
use Test;
use Simple::Redis;

plan 13;

my $e;  my @l;
my $host = '127.0.0.1';
my $port = 6379;
my $r = Simple::Redis.new;
$r.connect( $host, $port );

$r.mset( 'a', 1, 'b', 2, 'c', 3, 'd', 4 );
$e = $r.watch( 'a', 'b', 'c' );
is $e, Bool::True, '1 ok';

$e = $r.unwatch();
is $e, Bool::True, '2 ok';

$e = $r.multi();
is $e, Bool::True, '3 ok';
$e = $r.discard();
is $e, Bool::True, '4 ok';

$r.multi();
# commands in multi are queued and return '+QUEUED',
# mangled to return True
$e = $r.mset( 'a', 2, 'b', 3, 'c', 4, 'd', 5 );
is $e, True, '5 ok';
$e = $r.hset( 'h', 'a', 'h1' );
is $e, True, '6 ok';
$e = $r.incr( 'a' );
is $e, True, '7 ok';
$e = $r.hlen( 'h', 'b' );
is $e, False, '8 ok';
$e = $r.get( 'a' );
is $e, True, '9 ok';
@l = $r.exec();
is @l[0], True, '10 ok';

$r.multi();
$r.hset( 'h', 'a', 'h2' );
$e = $r.mget( "a", "b", "c" );
is $e, True, '11 ok';
$r.get( 'a' );
@l = $r.exec();
#say "|",  @l.perl;
is @l, ["0", ["3", "3", "4"], "3"], "12 ok";


$r.multi();
$r.hset( 'h', 'a', 'h1' );
$e = $r.discard();
is $e, Bool::True, '13 ok';

done;

