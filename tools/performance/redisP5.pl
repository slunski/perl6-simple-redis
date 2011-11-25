#!/usr/bin/perl -w

use Time::HiRes;
my $s;  my $e;

use Redis;
sub p1 {
	print "Pure Perl5 Redis:   ";
	my $r = Redis->new;

	$s = Time::HiRes::time;

	for( 1..10000 ) { $r->ping };

	$e = Time::HiRes::time;

	print $e - $s, "\n";

	$r->quit;
}


# Redis::hiredis use C bindings wroted by Redis author
use Redis::hiredis;
sub p2 {
	print "Redis::hiredis pipelined:  ";
	my $redis = Redis::hiredis->new();

	$s = Time::HiRes::time;

	$redis->connect('127.0.0.1', 6379);
	for( 1..10000 ) { $redis->command('ping') };

	$e = Time::HiRes::time;
	print $e - $s, "\n";
}

sub p3 {
	print "Redis::hiredis pipelined:\n";
	my $redis = Redis::hiredis->new();
	$s = Time::HiRes::time;
	$redis->connect('127.0.0.1', 6379);
	for( 1..10000 ) { $redis->append_command('ping') };
	$m = Time::HiRes::time;
	print "  ", $m - $s, "  just concatenat commands\n";
	for( 1..10000 ) { $set_status = $redis->get_reply() };

	$e = Time::HiRes::time;
	print "  ", $e - $s, "  total\n";
}

p1;
p2;
p3;

#use Benchmark;
#timethis( 1, &p1 );
# Benchmark not used becouse 10k is to small for Perl :)
#timethis 1:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
#            (warning: too few iterations for a reliable count)

