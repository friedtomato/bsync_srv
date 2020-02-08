package Flog;

#require Exporter;
#@ISA = qw(Exporter);
#@EXPORT = qw(item_flow);

use Fsocket;
use Fstatus;

#OLOG;
#FLOG;
#NLOG;
#WLOG;

my $PREFIX_CLIENT;
my $PREFIX_HOST;
my $NETLOG_FLAG = 0;
my $NETLOG_IP = "192.168.0.1";
my $NETLOG_PORT = 8888;
my $NETLOG_FILE = "nlog";


sub open_olog {
  my ($logfile) = @_;
  open OLOG, ">$logfile" or die "Cannot open olog: $!\n";
  OLOG->autoflush(1);

}

sub open_wlog {
  my ($wlogfile) = @_;
  open WLOG,">$wlogfile" or die "Cannot open wlog: $!\n";
  WLOG->autoflush(1);
}

sub open_flog {
  my ($logfile,$hostname,$cliname,$net_flag,$srv_ip,$net_port) = @_;
  open FLOG,">$logfile" or die "Cannot open flog: $!\n";
  FLOG->autoflush(1);
  $PREFIX_CLIENT = $cliname;
  $PREFIX_HOST = $hostname;
  $NETLOG_FLAG = $net_flag;
  $NETLOG_IP = $srv_ip;
  $NETLOG_PORT = $net_port;
}

# for the child reading from socket and writing to file
sub open_nlog {
  my($logfile,$flag) = @_;
  $NETLOG_FILE = $logfile;
  if($flag == 1){ # wipe the nlog
    open NLOG,">$logfile" or die "Cannot open nlog: $!\n";
    my $ntime = time();
    #print NLOG "[$ntime] start\n";
    close NLOG;
  }
  else{ # open nlog
    open NLOG,">>$logfile" or die "Cannot open nlog: $!\n";
    NLOG->autoflush(1);
  }
}

sub item_flog {
  my ($item) = @_;
  Fstatus::get_status();
  my $thro = Fstatus::parse_thro();
  my $temp = Fstatus::parse_temp();
  my $volts = Fstatus::parse_volts();

  my $ntime = time();
  my ($item1,$item2) = split /~/,$item;
  print FLOG "[$ntime]~$item1~$temp|$thro|$volts~$item2\n";
  $item = "$item1~$temp|$thro|$volts~$item2";

  #print FLOG "[$ntime]~$item\n";
  if($NETLOG_FLAG){
	  #Fsocket::wnetlog_item($NETLOG_IP,$NETLOG_PORT,"$item\n");
    Fsocket::wnetlog_item($NETLOG_IP,$NETLOG_PORT,"$item\n");
  }
}

sub item_wlog {
  my ($item) = @_;

  my $ntime = time();
  print WLOG "[$ntime]~$item\n";
  print "[$ntime]~$item\n";
 
  #if($NETLOG_FLAG){
    Fsocket::wnetlog_item($NETLOG_IP,$NETLOG_PORT,"$item\n");
    #}
}

sub item_olog {
  my ($item) = @_;

  my $ntime = time();
  print OLOG "[$ntime] $item\n";

}

sub item_nlog {
  my ($item) = @_;
  my $ntime = time();
  print NLOG "[$ntime]~$item";
}

sub close_olog {
  close OLOG;
}

sub close_flog {
  close FLOG;
}

sub close_wlog {
  close WLOG;
}

sub close_nlog {
  close NLOG;
}

1;
