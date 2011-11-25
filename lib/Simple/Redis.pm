#module Simple::Redis {

use v6;

class Simple::Redis:auth<github:slunski>:ver<0.4.7> {

	# BEGIN {

	# Syntax:
	# 'commandName' => (paramsNum, responseType)
	# paramsNum: -1: vararg; rest: num of params
	# responseType: 1: status only; 2: Int; 3: Str; 4: Bulk; 5: Multi-Bulk
	# Comment: responseType is nearly not used. Case (x,1) used for faster method return.
	# 	Response parsing is done in 'protocol way' by 1st character checking.
	#	Static table return code checking breaks eg. on transactions, where '+QUEUED' is
	#	returned for all commands in transaction body.

	has $!sock; # is rw;
	has $!errormsg = Any; # is rw;
	has Str $!infomsg = ''; # is rw;
	# SIMPLE - blocking, create command string, send, receive and parse, just work
	# PIPE - collect commands strings, send all, then read replies
	has $!mode = 'SIMPLE'; # is rw;
	has Str $!pipedCommands = ''; # is rw;
	has Int $!pipedCount = 0; # is rw;
	has Str $!pool = ''; # is rw;

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
				# Commands sanity checks ?
				my $cmd = self!__prepare_cmd( $name, @rest ) or return False;
				#self!__prepare_cmd( $name, @rest ) or return False;
				if $!mode eq 'SIMPLE' {
					#self!__parse_result( $name, @rest );
					self!__parse_result();
				} else {
					$!pipedCommands ~= $cmd;
					#$!pipedCount++;
				}
			}
		);
	}

	#} # BEGIN end

	method sendCommands() {
		#$!sock.send( $!pipedCommands ) or return False;
		$!sock.send( $!pool ) or return False;
	}

	method getResponses() {
		my @rs;
		my $a;
		loop ( my $i = $!pipedCount; $i > 0; $i--) {
			$a = self!__parse_result();
			if $!errormsg {
				return @rs;
			}
			push @rs, $a;
			#$!pipedCount--;
		}
		return @rs;
	}


	method setMode( Str $m ) { $!mode = $m; }  # some tests needed before assign

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
	
	method echo( $str! ) {
		my Str $cmd = "*2\r\n\$4\r\necho\r\n\$" ~ $str.bytes ~ "\r\n$str\r\n";
		$!sock.send( $cmd ) or return False;
		
		my Str $resp = $!sock.get() or return False;
		#my $len = substr( $resp, 1, $resp.bytes );
		#$resp = $!sock.recv( $len.Int );
		$resp = $!sock.get() or return False;
		return $resp;
	}

	#method !__cmd_gen( Str $command!, *@params ) {
	method !__prepare_cmd( Str $command!, *@params ) {
		my $syntax = %redisCommands{ $command };

		#if ! $syntax {
		#	$!errormsg = "Unknown command: $command";
		#	return False;
		#}

		my Int $n = @params.elems;
		# Server will detect params mismatch but by checking
		# here we avoid unnecesary network round trip
		if $syntax[0] != $n && $syntax[0] != -1 {
			if $syntax[0] < $n {
				$!errormsg = "To much parameters";
				return False
			} else {
				$!errormsg = "To few parameters";
				return False;
			}
		}

		# C 'errno'-like field, cleaned here in every command call
		$!errormsg = '';

		# Command construction
		my Str $cmd;
		#my $cmd;
		my $clen;
		if $syntax[0] == 0 {
			# Command do not have params, send it without wrapping
			$cmd = "$command\r\n";
		} else {
			$n++; # +1 - command as param matters in protocol
			# Commands are send in multi-bulk format
			$clen = $command.bytes;

			$cmd = "*$n\r\n\$$clen\r\n$command\r\n";

			my $plen;
			my $p;
			if @params.elems == 1 {
				$p = shift @params;
				$plen = $p.bytes;
				$cmd ~= "\$$plen\r\n$p\r\n";
			} else {
			for @params -> $p {
				$plen = $p.bytes;
				$cmd ~= "\$$plen\r\n$p\r\n";
			}
		}
		}

		# Command sending if SIMPLE mode
		if $!mode eq 'SIMPLE' {
			$!sock.send( $cmd ) or return False;
		} elsif $!mode eq 'PIPE' {
			 #$!pool ~= $cmd;
			 return $cmd;
		} else { 
			$!errormsg = 'Bad mode !';
			return False;
		}
	}


	#method !__parse_result( Str $command!, *@params ) {
	method !__parse_result() {
		# Response parsing
		#my $syntax = %redisCommands{ $command };

		my Str $resp;
		my $data;
		my $prefix;
		my @mblist;

		# mbmode: 0 - return single value; 1 - multi-bulk
		my Int $mbmode = 0;
		# Default loop count is 1 for getting single value
		my $cnum = 1;

		$resp = $!sock.get() or return False;
		$prefix = substr( $resp, 0, 1 );
		# second part of response used by all cases
		$data = substr( $resp, 1, $resp.bytes );

		if $prefix eq '*' {
			$mbmode = 1;
			$cnum = $data;
		}

		# Real loop only for * (multi-bulk), in other cases only once
		loop (my $i=0; $i < $cnum; $i++) {
			if $mbmode {
				# Read next line of reply
				$resp = $!sock.get() or return False;
				# ($prefix,$data) = $headtail( $resp );  # C/asm level would be nice :)
				$prefix = substr( $resp, 0, 1 );
				$data = substr( $resp, 1, $resp.bytes );
			}
			given $prefix {
				when '-' {
					#$!errormsg = $command ~ ": " ~ $data;
					$!errormsg = $data;
					$data = False;
				}
				when '+' {
					# returning status and in-transaction commands handling
					#if $syntax[1] == 1 || $data eq 'QUEUED' {
					if $data eq 'OK' || $data eq 'QUEUED' {
						$data = True;
						#next;
					}

					# Command returning string handling
					# And already assigned...
					#$data;
				}
				when ':'  {
					# Integer commands handling
					#$data;
				}
				when '$' {
					# Bulk commands, format: '$msgLen\r\n'
					if $data == -1  {
						# Nil
						$data = Any;
						#next;
					} else {
						my $len = $data;
						$data = $!sock.get();
						while $data.bytes < $len {
							$data ~= "\r\n" ~ $!sock.get();
						}
					}
					#$data;
				}
				when '*' {
					# here we parse internal multi-bulk, eg. inside transactions
					# only one lvl of nesting m-b is allowed so just loop - not recursive call
					my @list = ();

					# -1 indicate Null Multi Bulk
					if $data == -1 {
						push @list, False;
						next;
					} else {
						my $count = $data;
						#my Str $p;
						#my $line;
						loop (my $m=0; $m < $count; $m++) {
							my $line = $!sock.get();
	
							my Str $p = substr( $line, 0, 1 );
							my $len = substr( $line, 1, $line.bytes );

							# check if bulk starts with '+' or ':' - one-line response,
							# '-' too ?
							if $p eq '+' || $p eq ':' {
								# in this case $len(gth) is value...
								push @list, $len;
								next;
							}
	
							# check if that particular bulk is empty
							if $len == -1 {
								push @list, Any;
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
				}
				default {
					# Not reachable
					$!errormsg = 'Protocol error';
					return False;
				}
			}  # end given
			push @mblist, $data if $mbmode == 1; 
		}  # End command parse loop
		return $data if $mbmode == 0;
		return @mblist
	}

	method sync() {
		$!errormsg = "Command for use by slave storage only";
		return False;

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
