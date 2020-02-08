package Comm;
use IO::Socket::INET;


sub run_comm_srv {
  my($socket,$timeout) = @_;

  my $tmp_comm;
  my $con;  
  $con = $socket->accept(); 
  $con->recv($tmp_comm,1024);
  return $tmp_comm;  
}

1;
