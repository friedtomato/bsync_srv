package Fsocket;
use IO::Socket::INET;

# ----- SERVER LIB --------

my $BCAST_SOCKET;
my $LISTEN_SOCKET;
my $COM_SOCKET;
my $NETLOG_SOCKET;
my $NETLOG_IP;
my $NETLOG_PORT;
my $NETLOG_WAIT = 0;


sub bcast_socket {
  my ($ip,$port) = @_;

  my $bcast_socket = new IO::Socket::INET (
  	PeerPort	=> $port,
	PeerAddr	=> inet_ntoa(INADDR_BROADCAST),
	Proto		=> 'udp',
	LocalAddr	=> $ip,
	# Type		=> SOCK_DGRAM,
	Broadcast	=>1) or die "Cannot bind bcast socket: $@\n";
  $BCAST_SOCKET = $bcast_socket;
  return $bcast_socket;
}


sub listen_socket {
  my ($ip,$port,$timeout) = @_;

  my $listen_socket = IO::Socket::INET->new (
    LocalHost	=> $ip,
    LocalPort	=> $port,
    Proto	=> 'tcp',
    Listen	=> 20,
#    Timeout	=> $timeout,
    Blocking	=> 0,
    Reuse	=> 1) or die "Cannot bind listen socket: $@\n";
  $LISTEN_SOCKET = $listen_socket; 
  return $listen_socket;
}

sub local_socket {
  my ($sock_path) = @_;

  unlink($sock_path);
  my $local_socket = IO::Socket::UNIX->new (
    Type	=> SOCK_STREAM,
    Local	=> $sock_path,
    Listen	=> 2
#    Blocking	=> 0
  ) or die "Cannot create local socket $sock_path: $@\n";
  $COM_SOCKET = $local_socket;
  return $local_socket;
}

sub netlog_socket {
  my ($ip,$port) = @_;
  my $netlog_socket = IO::Socket::INET->new (
    LocalHost	=> $ip,
    LocalPort	=> $port,
    Proto	=> 'tcp',
    Listen	=> 10,
    Reuse	=> 1) or die "Cannot bind listen socket: $@\n";
  $NETLOG_SOCKET = $netlog_socket;
  $NETLOG_PORT = $port;
  $NETLOG_IP = $ip;
  return $netlog_socket;
}

sub send_bcast {
  my ($mesg) = @_;

  $BCAST_SOCKET->send($mesg) or die "Bcast failed: $!\n";
  return 1;
}

# log via socket (along with the logs from clients)
sub wnetlog_socket {
  my ($ip,$port) = @_;

  my $wnetlog_socket;
  while(!$wnetlog_socket){
    $wnetlog_socket = IO::Socket::INET->new (
  	    PeerHost	=> $ip,
	    PeerPort	=> $port,
	    Proto		=> 'tcp');
    #sleep 1;
  }
  return $wnetlog_socket;
}

# log via socket (along with the logs from the clients)
sub wnetlog_item {
  my($netlog_ip,$netlog_port,$mesg) = @_;

  my $sock = wnetlog_socket($netlog_ip,$netlog_port);
  $sock->send($mesg);
  shutdown($sock,1);
  $sock->close();
  undef($sock);
}

sub close_socket {
  my ($socket) = @_;

  my $ret = shutdown($socket,2);
  if(!$ret){
    die "Socket shutdown failed: $!\n";
  }
  $socket->close();
  undef($socket);
}


sub check_in_procedure {
  my ($f_active_clients,$socket,$num_cli,$timeout) = @_;

  my $n_active_clients = 0;
  my $id_not_done = 1;
  my $cycle = 0;
  #Flog::item_flog("[CP] check-in procedure start");
  while($id_not_done){
     print "cycle[$cycle]: ";
    my $c_socket;
    while((!$c_socket) && ($cycle < $timeout)){
      $c_socket = $socket->accept();
      $cycle++;	    
    }
    if($cycle == $timeout){
      #print "leaving after timeout\n";
      return $f_active_clients;
    }
    my $c_address = $c_socket->peerhost();
    #print "$c_address ";
    my $client_id = "";
    $c_socket->recv($client_id,1024);
    my $ok_data = "ok";
    $c_socket->send($ok_data);
    my ($str,$num) = split "-",$client_id;
    #print " clientid=$client_id ($str $num)";
    # new one to check in
    if((!defined($f_active_clients->{"$num"})) and ($client_id ne "")){
      $f_active_clients->{"$num"} = $cycle;
      $n_active_clients++;
      #print " new client\n";
      #Flog::item_flog("[CP] new connection from $c_address [$client_id]");
      #Flog::item_olog("[CP] $client_id OK [first time]");
    }  
    else{
      if(($f_active_clients->{"$num"} < $cycle) and ($client_id ne "")) {
        $n_active_clients++;
        $f_active_clients->{"$num"}++;
	#print "cycle increased for key $num\n";
	# Flog::item_flog("[CP] connection from $c_address [$client_id]");
	# Flog::item_olog("[CP] $client_id OK [$cycle]");
      }
    }
    
    # all in 
    if($n_active_clients eq $num_cli){
      $id_not_done = 0;
    }
    # Flog::item_flog("[CP] checkin procedure end (active clients: $n_active_clients)");
  }
  return $f_active_clients;
}
  
sub send_cmd {
  my($command) = @_;

  my $cli = IO::Socket::UNIX->new (
	  Type	=> SOCK_STREAM,
	  Peer	=> '/tmp/bsyncsrvsock'
  )or die "can't do: $!\n";
  chomp $command;
  $cli->send($command);
  $cli->close();
}


1;
