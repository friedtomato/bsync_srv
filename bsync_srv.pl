#!/usr/bin/perl

use IO::Socket::INET;
use Sys::Hostname;
use IPC::Shareable;
#use strict;
use warnings;
use Flog;
use Fsocket;
use Comm;
use Header;
use Fwsocket;

# number of clients to check in
# volume on clients
my $VOL_CLI = "50";
my $VOL_INC = "10";
my $GO_CLI  = "go";
my $NGO_CLI = "ngo";
# bcast tryouts
my $BCAST_COUNTS = 1;
# autoflush on socket
  $| = 1;
# ------- LOGGING ---------
#my $FL_DNAME="/home/pi/dev/bsync";
my $FL_DNAME=$Header::FL_DNAME;
my $OL_DNAME=$FL_DNAME;
my $NL_DNAME=$FL_DNAME;
print "bsync_srv: ".$Header::FL_DNAME." \n";
my $FL_FNAME="flog";
my $OL_FNAME="olog";
my $NL_FNAME="nlog";
# --- hostname identification, PORTs, SOCKETs
my $host = hostname();
my ($name,$number) = split '-',$host;
my $CLI_NAME = "client-".$number;
my $MIP	= '192.168.0.1';
my $BPORT = 9999; # broadcast port
my $NLPORT = 8888;# netlog port 
my $LPORT = 7777; # listen port
my $WPORT = 5555; # wlan bcast port
my $NETLOG_FLAG = 1;
my $COM_SOCKET_PATH="/tmp/bsyncsrvsock";
my $LS_TIMEOUT = 2000;
# ------------------------
my $END_OF_THE_LINE = 0;


# parameter indicating the mode: manual / automatic
my $MODE = "manual";
if (defined($ARGV[0])){
  $MODE = $ARGV[0];
}

my $SIG_QUIT = 0;
$SIG{INT} = \&ctrl_c_handler;

sub ctrl_c_handler {
	$SIG_QUIT = 1;
}

my $pid = fork;
die "Fork failed: $!\n" if not defined $pid;

if ($pid){ # parent
	sleep 1;	
  	#print "parent for $pid waiting\n";
  	my $pcomm;
  	my $pflag;
  	tie $pcomm,'IPC::Shareable','data',{ create => 'true' } or die "parent tie pcomm failed $!\n";
  	tie $pflag,'IPC::Shareable','control',{ create => 'true' } or die "parent tie pflag failed $!\n";
  	#$pcomm = "empty";
  	$pflag = 0;
  	my $spid = fork;
  	if($spid){ # parent
		my $com_socket = Fsocket::local_socket($COM_SOCKET_PATH);
    		while ( (!$SIG_QUIT) and (my $con = $com_socket->accept()) ){
      			#print "accepted \n";	  
      			my $tmp_pcomm;	  
      			$con->recv($tmp_pcomm,1024);
      			print "received ".$tmp_pcomm."\n";
      			$pcomm = $tmp_pcomm;
      			$pflag = 1;
      			#print "pflag set to 1\n";
      			if(($MODE eq "auto") and (!$SIG_QUIT)){
        			while(($pflag) and (!$SIG_QUIT)){}
				#print "done waiting\n";
				$con->send("ok");
      			}
    		}
    
    		Fsocket::close_socket($com_socket);
		undef $socket;
    		waitpid(-1,0);
    		IPC::Shareable->clean_up_all;
    		print "parent exiting\n";
    		exit 1;
	}
	else{
  		# child # 2 - netlogger
  		#print "logger start\n";
  		my $netlog_socket = Fsocket::netlog_socket($MIP,$NLPORT);
  		# wipe the nlog
  		Flog::open_nlog("$NL_DNAME/$NL_FNAME",1);
  		while ((!$SIG_QUIT) and (my $netlog_con = $netlog_socket->accept())){
    			my $tmp_netlog_msg;
    			$netlog_con->recv($tmp_netlog_msg,1024);
    			Flog::open_nlog("$NL_DNAME/$NL_FNAME",0);
    			Flog::item_nlog($tmp_netlog_msg);
    			Flog::close_nlog();
			undef $netlog_con;
  		}
  		Fsocket::close_socket($netlog_socket);
		undef $socket;
  		print "child 2 exiting\n";
  
	}
	# child # 1
}
else{


  my $ccomm;
  my $ccomm_cli;
  my $cflag;
  tie $ccomm,'IPC::Shareable','data',{ create => 'true' } or die "child tie ccomm failed $!\n";
  tie $cflag,'IPC::Shareable','control',{ create => 'true' } or die "child tie cflag failed $!\n";
  $ccomm = "empty";
  $cflag  = 0;
  my $prev_ccomm = $ccomm;

  # open flog, netlog_flag = log also into the socket
  Flog::open_flog("$FL_DNAME/$FL_FNAME",$host,$CLI_NAME,$NETLOG_FLAG,$MIP,$NLPORT);
  Flog::open_olog("$OL_DNAME/$OL_FNAME");

  my $b_socket = Fsocket::bcast_socket($MIP,$BPORT);
  my $l_socket = Fsocket::listen_socket($MIP,$LPORT,$LS_TIMEOUT);
  Flog::item_flog("$host|$CLI_NAME|CLN=0/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=0|VOL=$VOL_CLI%:session start, all sockets open");

  my $f_active_clients;
  my $f_ccomm_hist;
  my $n_active_clients = 0;
  my $id_not_done = 1;
  my $loop_count = 0;
  my $log_print_loop = 40;
  while(!$END_OF_THE_LINE and !$SIG_QUIT){
    $loop_count++;
    if(!defined($f_ccomm_hist->{"$ccomm"})){
	    $f_ccomm_hist->{"$ccomm"} = 0;
    }
    #else{
    #	    $f_ccomm_hist->{"$ccomm"}++;
    #   }

    if($loop_count % $log_print_loop == 0){
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:loop=$loop_count");
    }
    # --- treat commands for listed clients ----
    my $com_par_num = split /\ /,$ccomm;
    if ($com_par_num > 1){ # clients names used in the cmd
    	($ccomm,$ccomm_cli) = split /\ /,$ccomm;
	#print "$ccomm - $ccomm_cli\n";
    }
    else{
	$ccomm_cli = "";
    }
    # -------------

    if ($ccomm eq "checkin") {
	    print "$ccomm is checkin??\n";
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }

	    if($n_active_clients == $Header::NUM_CLI){
		    $ccomm = "empty";
		    $prev_ccomm = "checkin";
		    #$cflag = 0;
	    }
	    else{
		    $f_active_clients = Fsocket::check_in_procedure($f_active_clients,$l_socket,$Header::NUM_CLI,$LS_TIMEOUT);
		    if(!defined($f_active_clients)){
			    if($loop_count % $log_print_loop == 0){
	    			    my $cnum = $f_ccomm_hist->{"$ccomm"};
				    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOS=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:undef");
			    }
			    $n_active_clients = 0;
		    }
        	    else{
			    $n_active_clients = scalar keys %$f_active_clients;
			    foreach my $key (keys %$f_active_clients){
				    print "*$key*\n";
			    }
			    my $list_clients = join(',client-',keys %$f_active_clients);

			    $list_clients = "client-".$list_clients;
			    my $cnum = $f_ccomm_hist->{"$ccomm"};
		 	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:$list_clients");
			    # if($n_active_clients == $Header::NUM_CLI){
			    #    $prev_ccomm = "checkin";
			    #    $ccomm = "empty";
			    #    $cflag = 0;
			    #}  
		    }
	    }
	    #$prev_ccomm = "checkin";
    }
    elsif ($ccomm eq "runmpv!") {
	    sleep 1;
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");	  
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm"; 	    
		    }
		    Fsocket::send_bcast($packet); 
		    $attempts--;
	    }
	    $prev_ccomm = "runmpv!";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "runmpv") {
	    sleep 1;
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");	  
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    #sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm"; 	    
		    }
		    Fsocket::send_bcast($packet); 
		    $attempts--;
	    }
	    $prev_ccomm = "runmpv";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "pausempv") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    #sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm"; 
		    }	    
		    Fsocket::send_bcast($packet); 
		    $attempts--;
	    }
	    $prev_ccomm = $ccomm;
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }	    
    elsif ($ccomm eq "resetmpv") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    #sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm"; 	   
		    } 
		    Fsocket::send_bcast($packet); 
		    $attempts--;
	    }
	    $prev_ccomm = $ccomm;
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "incvol") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    $VOL_CLI = $VOL_CLI + $VOL_INC;
	    while($attempts){
		    #sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = $ccomm;
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "decvol") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    $VOL_CLI = $VOL_CLI - $VOL_INC;
	    while($attempts){
		    #sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = $ccomm;
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "prjon") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOM=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "prjon";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "prjoff") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "prjoff";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "prjstatus") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CF=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "prjstatus";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "pinuphs") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "pinuphs";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "pindownhs") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "pindownhs";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "pinupl") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "pinupl";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "pindownl") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "pindownl";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "quitsession") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "quitsession";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "quitssln") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    my $attempts = $BCAST_COUNTS;
	    while($attempts){
		    sleep 1;
		    my $packet;
		    if($ccomm_cli ne ""){
			    $packet = "$ccomm_cli:$VOL_CLI%:$ccomm";
		    }
		    else{
			    $packet = "$GO_CLI:$VOL_CLI%:$ccomm";
		    }
		    Fsocket::send_bcast($packet);
		    $attempts--;
	    }
	    $prev_ccomm = "quitssln";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "wcheckin") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wcheckin";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wlup") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wlup";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wldown") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wldown";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wbdown") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wbdown";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wbup") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm." ".$ccomm_cli);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wbup";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wbiup") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wbiup";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wbidown") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wbidown";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wred") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm." ".$ccomm_cli);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wred";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wblue") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm." ".$ccomm_cli);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wblue";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wgreen") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm." ".$ccomm_cli);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wgreen";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "wbset") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sending $ccomm bcast");
	    Fwsocket::wbcast_socket($WPORT);
	    Fwsocket::send_wbcast($ccomm." ".$ccomm_cli);
	    Fwsocket::close_wbcast_socket();
	    $prev_ccomm = "wbset";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "reset") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    $n_active_clients = 0;

	    undef $f_active_clients;

	    if($prev_ccomm ne $ccomm){
		    my $cnum = $f_ccomm_hist->{"$ccomm"};
		    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:reset clients ($n_active_clients)");
	    }
	    $prev_ccomm = "reset";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "list") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:list of clients");
	    if($prev_ccomm ne $ccomm){
#		    Flog::item_flog("$host|$CLI_NAME|CN=$n_active_clients/$Header::NUM_CLI|M=$MODE~CF=$cflag|LC=$prev_ccomm|C=$ccomm|V=$VOL_CLI%:active clients $n_active_clients");
		    if(defined($f_active_clients)){
				    foreach my $key (keys %{$f_active_clients}){
					    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:client-$key");
				    }
                    }
	    }
	    $prev_ccomm = "list";
	    $ccomm = "empty";
	    $ccomm_cli = "";
	    #$cflag = 0;
    }
    elsif ($ccomm eq "sleep"){
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    my $cnum = $f_ccomm_hist->{"$ccomm"};
	    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:sleeping for $ccomm_cli sec");
	    sleep $ccomm_cli;
	    $prev_ccomm = "sleep";
	    $ccomm = "empty";
	    $ccomm_cli = "";
    }
    elsif ($ccomm eq "empty") {
	    if(!defined($f_ccomm_hist->{"$ccomm"})){
		    $f_ccomm_hist->{"$ccomm"} = 1;
	    }
	    else{
		    $f_ccomm_hist->{"$ccomm"}++;
	    }
	    if($prev_ccomm ne $ccomm){
		    my $cnum = $f_ccomm_hist->{"$ccomm"};
		    Flog::item_flog("$host|$CLI_NAME|CLN=$n_active_clients/$Header::NUM_CLI|MOD=$MODE~CFL=$cflag|LCO=$prev_ccomm|COM=$ccomm|CHI=$cnum|VOL=$VOL_CLI%:$ccomm");
	    }
	    $ccomm = "undef";
    }
    else {
	    #Flog::item_flog("comm: no command");
    }

    if(($cflag) and ($ccomm eq "undef")){
	    $cflag = 0;
    }    


    #$id_not_done = 1;
    #$f_active_clients = "";
    #$n_active_clients = 0;
  }
  
  Fsocket::close_socket($b_socket);
  Fsocket::close_socket($l_socket);
  undef $b_socket;
  undef $l_socket;
  Flog::close_olog;
  Flog::close_flog;
  print "child 1 exiting\n";
  foreach my $key (keys %$f_active_clients){
	  delete $f_active_clients->{"$key"};
  }
  #delete $f_active_clients;
  undef $f_active_clients;
}
