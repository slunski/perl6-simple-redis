use v6;

class Simple::Redis:auth<github:slunski>:ver<0.2.2> {
	#BEGIN {
		for <bgrewriteaof bgsave discard flushall flushdb ping save unwatch dbsize lastsave> -> $name {
			Simple::Redis.HOW.add_method(
				Simple::Redis, $name, method () {
					return self!__cmd_zeroone( $name )
				}
			);
		}
		
		for <auth decr exists incr persist select strlen ttl type> -> $name {
			Simple::Redis.HOW.add_method(
				Simple::Redis, $name, method ( $param ) {
					return self!__cmd_zeroone( $name, $param )
				}
			);
		}

	#has %!redisCommandsMulti = {
	#our %redisCommandsMulti = { 
	my %redisCommandsMulti = { 
		'APPEND' => (2,2),
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
		'WATCH' => (-1,1),
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

	
	#my @a = %!redisCommandsMulti.keys; 

		#for <del decrby expire expireat getbit getrange getset hdel hget hset hexists lindex linsert lpop lpush lpushx lrange lrem lset ltrim mget setbit> -> $name {
		#for %!redisCommandsMulti.keys -> $name {
		for %redisCommandsMulti.keys -> $name {
			my $n = lc $name;
			Simple::Redis.HOW.add_method(
				Simple::Redis, $n, method ( *@rest ) {
					return self!__cmd_gen( $n, @rest )
				}
			);
		}

	#} # BEGIN end

	has $!sock; # is rw;
	has Str $!errormsg = ''; # is rw;

	method connect( $host, $port ) {
		$!sock = IO::Socket::INET.new( :$host, :$port );
		return True if $!sock.defined;
		return False;
	}

	method quit() {
		$!sock.send( "QUIT\r\n" ) or return False;
		#my $resp = $!sock.recv();
		my $resp = $!sock.get();
		$!sock.close();
		return True if $resp eq "+OK";
		return False;
	}

	method info {
		$!sock.send( "INFO\r\n" ) or return False;
		my $info;
		my $l;
		# Or use .recv and get everything in one call
		while $l = $!sock.get()  {
			$info ~= $l ~ "\n";
		}
		return $info;
	}

	method errormsg() {
		return $!errormsg;
	}

#	method !__parse_response() {
#		# Not used yet
#		my $data = $!sock.get();
#		return False if ! $data;
#
#		my $c = substr( $data, 0, 1 );
#		#my $rest = substr( $data, 1, $data.chars );
#		given $c {
#			when '-' { return (False , $data) }
#			when '+', ':' {
#				my $rest = substr( $data, 1, $data.chars );
#				return (True, $rest) } # String or Int
#			when '$' { return (True, $data) } # Bulk testing
#			when '*' { return (True, $data) } # Multi-Bulk testing
#			default { return (False, $data) }
#		}
#	}

	method set( $key, $value ) {
		my $cmd = "*3\r\n\$3\r\nSET\r\n";
		$cmd ~= "\$" ~ $key.bytes ~ "\r\n" ~ $key ~ "\r\n\$" ~ $value.bytes ~ "\r\n" ~ $value ~ "\r\n";
		$!sock.send( $cmd ) or return False;
		my $resp = $!sock.get();
		return True if $resp ~~ '+OK';
		return False;
	}
	
	method get( $key ) {
		my $cmd = "*2\r\n\$3\r\nGET\r\n";
		$cmd ~= "\$" ~ $key.chars ~ "\r\n" ~ $key ~ "\r\n";
		$!sock.send( $cmd ) or return False;
		my $resp = $!sock.get();

		my $pfx = substr( $resp, 0, 1 );
		if $pfx eq '-' {  # Protocol error
			$!errormsg = $resp;
			return False;
		}

		# Length of value after '$'
		my $num = substr( $resp, 1, $resp.chars );
		if $num < 0 {
			# -1 - "No such key", return empty
			#return Nil;
			return '';
		} else {
			my $data = $!sock.get();
			chomp $data;
			return $data;
		}
	}

	method echo( $str! ) {
		my $cmd = "*2\r\n\$4\r\necho\r\n\$" ~ $str.bytes ~ "\r\n$str\r\n";

		$!sock.send( $cmd ) or return False;
		
		my $resp = $!sock.get() or return False;
		#my $len = substr( $resp, 1, $resp.bytes );
		#$resp = $!sock.recv( $len.Int );
		$resp = $!sock.get() or return False;
		return $resp;
	}

	# Syntax: 'commandName' => (paramsNum, responseType)
	# responseType: 1: status only; 2: Int; 3: Str; 4: Bulk; 5: Multi-Bulk
	has %!redisCommands = {
	# Commands with zero params
		'BGREWRITEAOF' => (0,1),
		'BGSAVE' => (0,1),
		'DISCARD' => (0,1),
		'FLUSHDB' => (0,1),
		'FLUSHALL' => (0,1),
		'MULTI' => (0,1), # FIXIT + test 
		'PING' => (0,1),
		'RANDOMKEY' => (0,4), # FIXIT + test 
		'SAVE' => (0,1),
		'UNWATCH' => (0,1),
		'DBSIZE' => (0,2),
		'LASTSAVE' => (0,2),
	# Commands with one param
		'AUTH' => (1,1), # FIXIT + test
		'SELECT' => (1,1),
		'DECR' => (1,2),
		'EXISTS' => (1,2),
		'INCR' => (1,2),
		'PERSIST' => (1,2),
		'STRLEN' => (1,2),
		'TTL' => (1,2),
		'TYPE' => (1,3)
	}


	# Commands with one and two parameter
	method !__cmd_zeroone( Str $command!, $param? ) {
		my $syntax = %!redisCommands{ uc $command };
		return "Unknown command: $command" if ! $syntax;

		my $cmd;
		if $syntax[0] == 0 {
			$cmd = "$command\r\n";
		} else {
			#$syntax = %!redisCommands{ uc $command };
			my $clen = $command.bytes;
			my $plen = $param.bytes;
			$cmd = "*2\r\n\$$clen\r\n$command\r\n\$$plen\r\n$param\r\n";
		}

		$!sock.send( $cmd ) or return False;
		my $resp = $!sock.get() or return False;

		my $prefix = substr( $resp, 0, 1 );
		return False if $prefix eq '-'; # DB send '-ERR ...'
		#say "C1|$resp|C1";

		given $syntax[1] {
			when 1 { return True } # Tested above: not error so '+OK'
			when 2|3 { return substr( $resp, 1, $resp.bytes ) } # Int or String
			default { return False }
		}
	}

	#has %!redisCommandsMulti = {

	method !__cmd_gen( Str $command!, *@params ) {
		my $syntax = %redisCommandsMulti{ uc $command };
		if ! $syntax {
			$!errormsg = "-Unknown command: $command";
			return False;
		}
		my $n = @params.elems;
		if $syntax[0] != $n {
			if $syntax[0] == -1 {

			} elsif $syntax[0] < $n {
				$!errormsg = "-To much parameters";
				return False
			} else {
				$!errormsg = "-To few parameters";
				return False;
			}
		}
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
			$!sock.send( $cmd ) or return False;

			my $resp = $!sock.get() or return False;
			my $prefix = substr( $resp, 0, 1 );

			#my $debug = '';
			my $len;  my $data;
			given $prefix {
				when '-' { $!errormsg =  $resp;  return False; }
				when '+' {
					return True if $syntax[1] == 1;  # Tested above: not error so '+OK'
					return substr( $resp, 1, $resp.bytes )  # String
				}
				when ':'  {
					return substr( $resp, 1, $resp.bytes ) } # Integer
				when '$' {  # Bulk; $MsgLen\r\n
					$len = substr( $resp, 1, $resp.bytes );
					return False if $len == -1;  # Nil
					$data = $!sock.get();
					# With Perl6/Parrot buffering .getline do all work: chomp
					return substr( $data, 0, $len );
					#return $data;
				}
				when '*' {  # Multi-Bulk; '*NumMsg\r\n...
					my $count = substr( $resp, 1, $resp.bytes );
					return False if $count == -1;  # Nil
					my @list;
					my $partone;
					my $val;
					loop (my $i=0; $i<$count; $i++) {
						$partone = $!sock.get();
						$len = substr( $partone, 1, $resp.bytes );
						next if $len == -1;  # Nil
						$data ~= $!sock.get();
						while $data.bytes < $len {
							$data ~= "\r\n" ~ $!sock.get();
						}
						push @list, $data;
					}
					return @list;
				}
				default { return False }
			}
		}
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

