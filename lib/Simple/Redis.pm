#module Simple::Redis {

use v6;

class Simple::Redis:auth<github:slunski>:ver<0.4.3> {

	# BEGIN {

	# Syntax:
	# 'commandName' => (paramsNum, responseType)
	# paramsNum: -1: vararg; rest: num of params
	# responseType: 1: status only; 2: Int; 3: Str; 4: Bulk; 5: Multi-Bulk
	# Comment: responseType is nearly not used. Only (x,1) is used.
	# 	Response parsing is done in 'protocol way' by 1st character checking.
	#	Static/table approach breaks eg. on transactions, where '+QUEUED' is
	#	returned for all commands in transaction body.

	# const it should be...
	#our %redisCommands = { 
	#has %!redisCommands = {
	my %redisCommands = { 
		'BGREWRITEAOF' => (0,1),
		'BGSAVE' => (0,1),
		'FLUSHALL' => (0,1),
		'FLUSHDB' => (0,1),
		'PING' => (0,1),
		'SAVE' => (0,1),
		'DISCARD' => (0,1),
		'EXEC' => (0,5),
		'MULTI' => (0,1),
		'UNWATCH' => (0,1),
		'WATCH' => (-1,1),
		'DBSIZE' => (0,2),
		'LASTSAVE' => (0,2),
		'GET' => (1,4),
		'AUTH' => (1,1), # FIXIT + test
		'SELECT' => (1,1),
		'DECR' => (1,2),
		'EXISTS' => (1,2),
		'INCR' => (1,2),
		'PERSIST' => (1,2),
		'STRLEN' => (1,2),
		'TTL' => (1,2),
		'TYPE' => (1,3),
		'APPEND' => (2,2),
		'BLPOP' => (-1,5),
		'BRPOP' => (-1,5),
		'BRPOPLPUSH' => (3,4),  # if timeout then (3,5)
		'DEL' => (-1,2),
		'DECRBY' => (2,2),
		'EXPIRE' => (2,2),
		'EXPIREAT' => (2,2),
		'GETBIT' => (2,2),
		'GETRANGE' => (3,4),
		'GETSET' => (2,4), # FIXIT + test
		#'HDEL' => (-1,2), # in ver. 2.4+
		'HDEL' => (2,2),
		'HEXISTS' => (2,2),
		'HGET' => (2,4),
		'HGETALL' => (1,5),
		'HINCRBY' => (3,2),
		'HKEYS' => (1,5),
		'HLEN' => (1,1),
		'HMGET' => (-1,5),
		'HMSET' => (-1,1),
		'HSET' => (3,2),
		'HSETNX' => (3,2),
		'HVALS' => (1,5),
		'INCRBY' => (2,2),
		'KEYS' => (1,5), # FIXIT + test
		'LINDEX' => (2,4), # FIXIT + test
		'LINSERT' => (4,2), # FIXIT + test
		'LLEN' => (1,2), # FIXIT + test
		'LPOP' => (1,4), # FIXIT + test
		'LPUSH' => (-1,2), # FIXIT + test
		'LPUSHX' => (2,2),
		'LREM' => (3, 2),
		'LRANGE' => (3, 5),
		'LSET' => (3, 1),
		'LTRIM' => (3, 1),
		'MGET' => (-1,5), # FIXIT + test
		'MOVE' => (2,2),
		'MSET' => (-1,1), # FIXIT + test
		'MSETNX' => (-1,2), # FIXIT + test
		'RENAME' => (2,1),
		'RENAMENX' => (2,2),
		'RPOP' => (1,4),
		'RPOPLPUSH' => (2,4),
		'RPUSH' => (-1,4),
		'RPUSHX' => (2,2),
		'SADD' => (-1,2),
		'SCARD' => (1,2),
		'SDIFF' => (-1,5),
		'SDIFFSTORE' => (-1,2),
		'SETBIT' => (3,2),
		'SETEX' => (3,1),
		'SETNX' => (2,2),
		'SETRANGE' => (3,1),
		'SINTER' => (-1,5),
		'SINTERSTORE' => (-1,2),
		'SISMEMBER' => (2,1),
		'SLEVEOF' => (-1,5),  # Should be implemented as separate command
		'SLOWLOG' => (2,1),
		'SMEMBERS' => (1,5),
		'SMOVE' => (3,2),
		'SORT' => (-1,5), # Should be implemented as separate command
		'SPOP' => (1,4),
		'SRANDMEMBER' => (1,4),
		'SREM' => (-1,2),
		'SUNION' => (-1,5),
		'SUNIONSTORE' => (-1,2),
		'ZADD' => (-1,2),
		'ZCARD' => (1,2),
		'ZCOUNT' => (3,2),
		'ZINCRBY' => (3,4),
		'ZINTERSTORE' => (-1,2),
		'ZRANGE' => (-1,5),
		'ZRANGEBYSCORE' => (-1,5),
		'ZRANK' => (2,4), # Should be implemented as separate command
		'ZREM' => (-1,2),
		'ZREMRANGEBYRANK' => (3,2),
		'ZREMRANGEBYSCORE' => (3,2),
		'ZREVRANGE' => (-1,5),
		'ZREVRANGEBYSCORE' => (-1,5),
		'ZREVRANK' => (2,4), # Should be implemented as separate command
		'ZSCORE' => (2,4),
		'ZUNIONSTORE' => (-1,2) # Should be implemented as separate command
	}

	#for %!redisCommands.keys -> $name {
	for %redisCommands.keys -> $name {
		my Str $n = lc $name;
		Simple::Redis.HOW.add_method(
			Simple::Redis, $n, method ( *@rest ) {
				return self!__cmd_gen( $name, @rest )
			}
		);
	}

	#} # BEGIN end

	has $!sock; # is rw;
	has Str $!errormsg = ''; # is rw;
	has Str $!infomsg = ''; # is rw;

	method connect( $host, $port ) {
		$!sock = IO::Socket::INET.new( :$host, :$port );
		return True if $!sock.defined;
		return False;
	}

	method quit() {
		$!sock.send( "QUIT\r\n" ) or return False;
		my Str $resp = $!sock.get();
		$!sock.close();
		return True if $resp eq "+OK";
		return False;
	}

	method info {
		$!sock.send( "INFO\r\n" ) or return False;
		my Str $info;
		my Str $l;
		# Or use .recv and get everything in one call
		while $l = $!sock.get() {
			$info ~= $l ~ "\n";
		}
		return $info;
	}

	method errormsg() {
		return $!errormsg;
	}

	method set( $key, $value ) {
		my Str $cmd = "*3\r\n\$3\r\nSET\r\n";
		$cmd ~= "\$" ~ $key.bytes ~ "\r\n" ~ $key ~ "\r\n\$" ~ $value.bytes ~ "\r\n" ~ $value ~ "\r\n";
		$!sock.send( $cmd ) or return False;
		my Str $resp = $!sock.get();
		return True if $resp ~~ '+OK';
		return False;
	}
	
	#method get( $key ) {
	#	my Str $cmd = "*2\r\n\$3\r\nGET\r\n";
	#
	#	# Redis 'get' supports only strings but in API we allow anything
	#	# and relay on Perl auto-conversion in concatenation
	#	$cmd ~= "\$" ~ $key.chars ~ "\r\n" ~ $key ~ "\r\n";
	#	$!sock.send( $cmd ) or return False;
	#	my Str $resp = $!sock.get();
		
	#	# 'get' returns bulk started with '$'
	#	# Error replay starts with '-'
	#	my Str $pfx = substr( $resp, 0, 1 );
	#	if $pfx eq '-' {  # Protocol error
	#		$!errormsg = $resp;
	#		return False;
	#	}

	#	# Length of value after '$'
	#	my $num = substr( $resp, 1, $resp.chars );
	#	if $num < 0 {
	#		# -1 - "No such key", return empty
	#		return ;
	#	} else {
	#		# We can use .recv( $num );...
	#		my $data = $!sock.get();
	#		#chomp $data; # .get chomps nl
	#		return $data;
	#	}
	#}

	method echo( $str! ) {
		my Str $cmd = "*2\r\n\$4\r\necho\r\n\$" ~ $str.bytes ~ "\r\n$str\r\n";
		$!sock.send( $cmd ) or return False;
		
		my Str $resp = $!sock.get() or return False;
		#my $len = substr( $resp, 1, $resp.bytes );
		#$resp = $!sock.recv( $len.Int );
		$resp = $!sock.get() or return False;
		return $resp;
	}

	method !__cmd_gen( Str $command!, *@params ) {
		# for additional info about '+' returning commands
		$!infomsg = '';

		my $syntax = %redisCommands{ $command };
		if ! $syntax {
			$!errormsg = "-Unknown command: $command";
			return False;
		}
		my Int $n = @params.elems;
		if $syntax[0] != $n && $syntax[0] != -1 {
			if $syntax[0] < $n {
				$!errormsg = "-To much parameters";
				return False
			} else {
				$!errormsg = "-To few parameters";
				return False;
			}
		}
		#elsif $syntax[0] == -1 {
		# checks for commands with variable number of params
		#
		#
		#}

		$!errormsg = '';

		my $cmd;
		if $syntax[0] == 0 {
			$cmd = "$command\r\n";
		} else {
			my $clen = $command.bytes;
			$n++; # Command as param matters in protocol
			$cmd = "*$n\r\n\$$clen\r\n$command\r\n";
			
			for @params -> $p {
				my $plen = $p.bytes;
				$cmd ~= "\$$plen\r\n$p\r\n";
			}
		}

		# send command...
		$!sock.send( $cmd ) or return False;

		my $data;
		my $len;  my $cnum = 1;

		# state: 0 - return single value; 1 - multi-bulk
		my Int $state = 0;
		my @mblist;

		# ... and get result
		my Str $resp = $!sock.get() or return False;
		my Str $prefix = substr( $resp, 0, 1 );

		if $prefix eq '*' {
			$state = 1;
			$cnum = substr( $resp, 1, $resp.bytes );
		}

		loop (my $i=0; $i < $cnum; $i++) {
			if $state == 1 {
				$resp = $!sock.get() or return False;
				$prefix = substr( $resp, 0, 1 );
			}
			given $prefix {
				when '-' { $!errormsg =  $resp; $data = False; }
				when '+' {
					# commands returning status handling
					$data = substr( $resp, 1, $resp.bytes );
					if $syntax[1] == 1 || $data eq 'QUEUED' {
						$!infomsg = $resp;
						$data = True;
						next;
					}

					# string result handling
					$data = substr( $resp, 1, $resp.bytes );
				}
				when ':'  {
					$data = substr( $resp, 1, $resp.bytes ) } # Integer
				when '$' {  # Bulk; $MsgLen\r\n
					$len = substr( $resp, 1, $resp.bytes );
					if $len == -1  {
						# Nil
						$data = Any;
						next;
					}
					$data = $!sock.get();
					while $data.bytes < $len {
						$data ~= "\r\n" ~ $!sock.get();
					}
					#$data;
				}
				when '*' {
					# this case parse internal multi-bulk, eg. inside transactions

					my @list = ();

					my $count = substr( $resp, 1, $resp.bytes );
					# -1 indicate Null Multi Bulk
					if $count == -1 {
						push @list, False;
						next;
					}

					my Str $c;
					my $partone;
					my $val;
					loop (my $m=0; $m < $count; $m++) {
						$partone = $!sock.get();

						# / '+'+? (.*) { push @tails, $1 } <!> /  # TimToady++
						# lazy .comb would be nice here
						# ($c,) = $str.comb;
						$c = substr( $partone, 0, 1 );
						$len = substr( $partone, 1, $partone.bytes );

						# check if that particular bulk is empty
						if $len == -1 {
							push @list, Any;
							next;
						}

						# check if bulk starts with '+' or ':' - one-line response,
						# required at least by transactions
						# '-' too ?
						if $c eq '+' || $c eq ':' {
							# in this case $len(gth) is value...
							push @list, $len;
							next;
						}

						# else get content
						my $repl = $!sock.get();
						while $repl.bytes < $len {
							$repl ~= "\r\n" ~ $!sock.get();
						}
						push @list, $repl;
					}
					$data = @list;
				}
				default {
					# Protocol error if here
					return False;
				}
			}
			push @mblist, $data if $state == 1;
		}
		return @mblist if $state == 1;
		return $data;
	}

	method sync() {
		return "Command for use by slave storage only";

		#$!sock.send( "SYNC\r\n" ) or return False;
		## Flush socket
		#$!sock.get(); $!sock.get(); return True;
	}
}

=begin pod

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 Sylwester Łuński. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=end pod

#}
