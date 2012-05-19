use v6;

class Simple::Redis:auth<github:slunski>:ver<0.4.8> {

	has $!sock; # is rw;
	has $!errormsg = Any; # is rw;
	has Str $!infomsg = ''; # is rw;
	# SIMPLE - blocking, create command string, send, receive and parse, just work
	# PIPELINE - collect commands strings, send all, read replies
	our enum Mode <SIMPLE PIPELINE PUBSUB>;
	has Int $!mode = SIMPLE; # is rw;
	has Int $!pipedCount = 0; # is rw;
	has Str $!pool = ''; # is rw;

	BEGIN {
		# Methods for commands are created automatically

	# Syntax:
	# 'commandName' => (paramsNum, responseType)
	# paramsNum: -1: vararg; rest: num of params
	# responseType: 1: status only; 2: Int; 3: Str; 4: Bulk; 5: Multi-Bulk
	# Comment: responseType is nearly not used. Case (x,1) used for faster method return.
	# 	Response parsing is done in 'protocol way' by 1st character checking.
	#	Static table return code checking breaks eg. on transactions, where '+QUEUED' is
	#	returned for all commands in transaction body.

	# const it should be...
	#constant %redisCommands = {  # NYI
	my %redisCommands = { 
		'BGREWRITEAOF' => (0,1),
		'BGSAVE' => (0,1),
		'FLUSHALL' => (0,1),
		'FLUSHDB' => (0,1),
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
		#'HDEL' => (2,2),
		'HDEL' => (-1,2), # in ver. 2.4+
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

	for %redisCommands.kv -> $name, $val {
		my Str $n = lc $name;
		if $val[0] == 0 {
			# For commands using "inline" protocol
			Simple::Redis.HOW.add_method(
				Simple::Redis, $n, method ( *@rest ) {
					my Str $cmd = "$n\r\n";
					if $!mode == SIMPLE {
						$!sock.send( $cmd ) or return False;
						self!__parse_result();
					} else {
						# PIPELINE mode 
						$!pool ~= $cmd;
						$!pipedCount++;
					}
				}
			);
		} else {
			Simple::Redis.HOW.add_method(
				Simple::Redis, $n, method ( *@rest ) {
					my Str $cmd;
					my Int $m = @rest.elems;
					# Check params count vs command "definition"
					if $val[0] != $m && $val[0] != -1 {
						$!errormsg = 'Bad parameters count';
						return False;
					}
					# Commands are usually send in multi-bulk format
					my $clen = $n.bytes;
					my $plen;  my $p;
					if $m == 1 {
						$cmd = "*2\r\n\$$clen\r\n$n\r\n";
						$p = shift @rest;
						$plen = $p.bytes;
						$cmd ~= "\$$plen\r\n$p\r\n";
					} else {
						# +1 - command as param matters in protocol
						$m++;
						$cmd = "*$m\r\n\$$clen\r\n$n\r\n";
						for @rest -> $p {
							$plen = $p.bytes;
							$cmd ~= "\$" ~ $plen ~ "\r\n$p\r\n";
						}
					}
					if $!mode == SIMPLE {
						$!sock.send( $cmd ) or return False;
						self!__parse_result();
					} else {
						# mode PIPELINE
						$!pool ~= $cmd;
						$!pipedCount++;
					}
				}
			);
		}
	}

	} # BEGIN end

	#method sendCommands() {
	#	$!sock.send( $!pool ) or return False;
	#	$!pool = '';
	#	return True;
	#}

	method getResponses() {
		my @rs;
		my $a;

		#loop ( my Int $i = $!pipedCount; $i > 0; $i--) {
		loop ( my int $i = $!pipedCount; $i > 0; $i=$i-1) {
			$a = self!__parse_result();
			push @rs, $a;
		}
		return @rs;
	}

	method setMode( Int $m ) { $!mode = $m; }  # some tests needed before assign!

	method connect( $host, $port ) {
		$!sock = IO::Socket::INET.new( :$host, :$port );
		return False unless $!sock.defined;
		# autochop remove "\n" only, Redis use this
		$!sock.input-line-separator = "\r\n";
		return True
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

	method ping() {
		$!sock.send( "ping\r\n" ) or return False;
		my Str $resp = $!sock.get() or return False;
		return 'PONG' if $resp eq "+PONG";
		return False;
	}

	method !__parse_result() {
		my Str $resp;
		my Str $prefix;
		my Str $data;

		$resp = $!sock.get() or return False;

		$prefix = substr( $resp, 0, 1 );
		# second part of response used by all cases
		$data = substr( $resp, 1, $resp.bytes );
		if $prefix ne '*' {
			if $prefix eq '-' {
					#$!errormsg = $command ~ ": " ~ $data;
					$!errormsg = $data;
					return False;
			} elsif $prefix eq '+' {
				# returning status and in-transaction commands handling
				if $data eq 'OK' || $data eq 'QUEUED' {
					return True;
				}
				# Command returning string or integer handling
				return $data;
			} elsif $prefix eq ':' {
				return $data;
			} elsif $prefix eq '$' {
				if $data eq '-1'  {
					# protocol definition advise to return undefined value here
					return Any;
				} else {
					my $len = $data;
					$data = $!sock.get();
					while $data.bytes < $len {
						$data ~= "\r\n" ~ $!sock.get();
					}
					return $data;
				}
			}
		} else {
			# * (multi-bulk) replay parsing
			my $cnum = $data;
			my @mb = ();
			loop (my Int $i=0; $i < $cnum; $i++) {
				$resp = $!sock.get() or return False;
				$prefix = substr( $resp, 0, 1 );
				$data = substr( $resp, 1, $resp.bytes );
				if $prefix eq '-' {
						$!errormsg = $data;
						push @mb, False;
						next;
				} elsif $prefix eq'+' {
						# returning status and in-transaction commands handling
						#if $syntax[1] == 1 || $data eq 'QUEUED' {
						if $data eq 'OK' || $data eq 'QUEUED' {
							push @mb, True;
						}
						# Command returning string handling
						push @mb, $data;
						next;
				} elsif $prefix eq ':'  {
						push @mb, $data;
						next;
				} elsif $prefix eq '$' {
					# Bulk commands, format: '$len\r\ncontent_of_len_length'
					if $data eq '-1'  {
						push @mb, Any;
						next;
					} else {
						my $len = $data;
						$data = $!sock.get();
						while $data.bytes < $len {
							$data ~= "\r\n" ~ $!sock.get();
						}
						push @mb, $data;
						next;
					}
				} elsif $prefix eq '*' {
					# here we parse internal multi-bulk, eg. inside transactions
					# only one lvl of nesting m-b is allowed so just loop - not recursive call

					if $data eq '-1' {
						# -1 indicate Null Multi Bulk
						push @mb, Any;
					} else {
						my @list = ();
						my $count = $data;
						loop (my Int $m=0; $m < $count; $m++) {
							my Str $line = $!sock.get();
							my Str $p = substr( $line, 0, 1 );
							my $len = substr( $line, 1, $line.bytes );

							# check if bulk starts with '+' or ':' - one-line response,
							# Can '-' be found in m.b. ?
							if $p eq '+' || $p eq ':' {
								# in this case $len(gth) is value
								push @list, $len;
								next;
							} else {
								# check if that particular bulk is empty
								if $len == -1 {
									push @list, Any;
									next;
								}
								my Str $r = $!sock.get();
								while $r.bytes < $len {
									$r ~= "\r\n" ~ $!sock.get();
								}
								push @list, $r;
								next;
							}
						}  # End internal m-b loop
						push @mb, @list;
					}
				} else {
					$!errormsg = 'Protocol error';
					return False;
				}
			}
			return @mb;
		}  # Main parsing 'if'
	}  # End __parse 

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

Copyright (C) 2012 Sylwester Łuński. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=end pod

