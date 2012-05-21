#!/usr/bin/env perl6

my $h = "127.0.0.1";
my $p = '6379';

#say join ' ', IO::Socket::INET.^methods;

my $s = IO::Socket::INET.new( host => $h, port => $p.Int )or die();
$s.input-line-separator = "\r\n";

#$s.send( "info\r\n" );
$s.send( "config get save\r\n" );
say 'Reading...';
my $r = $s.recv();
say 'Got1: ', $r;


