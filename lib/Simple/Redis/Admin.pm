use v6;
use Simple::Redis;

class Simple::Redis::Admin is Simple::Redis {

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
method config {
# Forms: GET RESETSTAT SET 
}
method debug {
# Forms: object segfault 
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
