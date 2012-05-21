use v6;
use Simple::Redis;

class Simple::Redis::Admin is Simple::Redis {

method !sendrecv( Str $cmd ) {
	$.sock.send( $cmd ) or return False;

	# Using this from S::R will do everything we want...
	#self!__parse_result();
	
	# but P6 object system do not allow us, so we use this...
	# still, it is advanced content so let admins worry...
	my $re = $.sock.recv();

	return $re;
}

method bgrewriteaof {
	my Str $cmd = "bgrewriteaof\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return True if $resp eq '+Background append only file rewriting started';
	return False;
}
method bgsave {
	my Str $cmd = "bgsave\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return True if $resp eq '+Background saving started';
	return False;
}
method config( Str $sbc, *@param) {
# Forms: GET RESETSTAT SET 
	my Str $cmd = "config ";
	if $sbc eq 'restart' {
		$cmd ~= 'restart\r\n';
	} elsif $sbc eq 'get' {
		$cmd ~= "get @param[0]\r\n";
	} elsif $sbc eq 'set' {
		$cmd ~= 'set ';
		$cmd ~= @param.join( ' ' );
		$cmd ~= "\r\n";
	} else {
		return False;
	}
	return self!sendrecv( $cmd );
}
method object {
# Forms: REFCOUNT ENCODING IDLETIME

}
method debug( Str $sbc, Str $param? ) {
	my $cmd = "debug ";
	if $sbc eq 'segfault' {
		# FIX: commented for dev
		#$cmd ~= "segfault\r\n";

		my $cmd = "echo debug segfault\r\n";

	} elsif $sbc eq 'object' {
		say 'oo';
		$cmd ~= "object $param\r\n";
	} else {
		return False;
	}
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return $resp;

}
method info {
	$.sock.send( "info\r\n" ) or return False;
	my Str $info;
	my Str $l;
	# Or use .recv and get everything in one call
	while $l = $.sock.get() {
		$info ~= $l ~ "\n";
	}
	return $info;
}
method lastsave {
	my Str $cmd = "lastsave\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	my $p = substr( $resp, 0, 1 );
	return False unless $p eq ':';
	my $i = substr( $resp, 1, $resp.bytes );
	return $i;
}
method monitor {
}
method save {
	my Str $cmd = "save\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return True if $resp ~~ '+OK';
	return False;
}
method shutdown {
	# Forms: SAVE NOSAVE
	my Str $cmd = "shutdown\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return True if $resp ~~ '+OK';
	return False;
}
method slaveof {
	# Forms: NO ONE host port
	my Str $cmd = "slaveof\r\n";
	$.sock.send( $cmd ) or return False;
	my Str $resp = $.sock.get();
	return True if $resp ~~ '+OK';
	return False;
}
method slowlog {
# Forms: get len reset
}
method sync {
	$.sock.send( "SYNC\r\n" ) or return False;
	# Flush socket
	$.sock.get(); $.sock.get();
	return True;
}
method time {
}

}
