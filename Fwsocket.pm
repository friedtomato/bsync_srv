package Fwsocket;

use IO::Socket::INET;
use IO::Interface::Simple;
use Socket;

my $WBCAST_SOCKET;
my $WLISTEN_SOCKET;
my $IF_WLAN_IP;
my $WLISTEN_PORT;
my $IF_WLAN_NAME = "wlan0";
my $RESP_MAXLEN = 128;
my $RESP;


sub wbcast_socket {
	my ($port) = @_;
	if(!defined($IF_WLAN_IP)){
		_int_get_wlan_ip();
	}
	$WBCAST_SOCKET = IO::Socket::INET->new (
		PeerPort 	=> $port,
		PeerAddr 	=> inet_ntoa(INADDR_BROADCAST),
		Proto    	=> 'udp',
		LocalAddr	=> $IF_WLAN_IP,
		Broadcast	=> 1) or die "[wbcast_socket] cannot $@\n";
	return 1;
}

sub wlisten_socket {
	my ($port,$timeout) = @_;
	if(!defined($IF_WLAN_IP)){
		_int_get_wlan_ip();
	}
	#print "$IF_WLAN_IP\n";
	my $proto = getprotobyname("udp");
	my $paddr = pack_sockaddr_in($port,inet_aton($IF_WLAN_IP)) or die "pack $!\n";;
	socket(WL_SOCKET,PF_INET,SOCK_DGRAM,$proto) or die "socket $!\n";;
	bind(WL_SOCKET,$paddr) or die "bind $!\n";
	$WLISTEN_PORT = $port;
	return 1;	
}

sub wwrite_socket {
	my ($ip,$port) = @_;
	if(!defined($IF_WLAN_IP)){
		_int_get_wlan_ip();
	}
}

sub _int_get_wlan_ip {
	my $end = 0;
	while(!$end){
		my $if_wlan = IO::Interface::Simple->new($IF_WLAN_NAME);
		$IF_WLAN_IP = $if_wlan->address;
		if(defined($IF_WLAN_IP)){
			$end = 1;
		}
		undef $if_wlan;
	}
}

sub send_wbcast{
	my ($mesg) = @_;
	$WBCAST_SOCKET->send($mesg) or die "[send_wbcast] cannot send: $@\n";
}

sub wrecv {
	my $tmp;
	recv(WL_SOCKET,$tmp,$RESP_MAXLEN,0) or die "cannot recv $!\n";
	$RESP = $tmp;
	return $tmp;
}

sub close_wbcast_socket{
	shutdown($WBCAST_SOCKET,2);
	$WBCAST_SOCKET->close();
}

sub destroy_wbcast_socket{
	undef $WBCAST_SOCKET;
}
sub close_wlisten_socket{
	shutdown($WLISTEN_SOCKET,2);
	$WLISTEN_SOCKET->close();
}

sub destroy_wlisten_socket{
	undef $WLISTEN_SOCKET;
}

sub get_wlan_ip {
	return $IF_WLAN_IP;
}

1;
