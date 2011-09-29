#!/usr/bin/env perl6


sub foo( $name, |$rest ($p1?, $p2?, $p3?, *@more) ) {
	say $name;
	say $rest.perl;
	say join ' ', $rest;
}

foo( 'bar', 1, 2);


