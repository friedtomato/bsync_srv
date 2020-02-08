#!/usr/bin/perl -w

use strict;
use Header;
use Fwsocket;
use Flog;
use Fparse;

my $END_OF_LINE = 0;

$|=1;

print "wsync_srv: ".$Header::FL_DNAME."/".$Header::WL_FNAME."\n";

Flog::open_wlog($Header::FL_DNAME."/".$Header::WL_FNAME);
Fwsocket::wlisten_socket($Header::WLPORT,1);

while(!$END_OF_LINE){
	my $resp_str = Fwsocket::wrecv();
	print $resp_str."\n";
	my ($cli_num,$cli_name,$client_ip,$status,$ccomm,$ts,$del,$color,$br,$rssi) = Fparse::parse_wresp($resp_str);
	my $ip = Fwsocket::get_wlan_ip();
	Flog::item_wlog("$ip|$cli_name|WIP=$client_ip|WLN=0/$Header::NUM_CLI~RES=$status|COM=$ccomm|WTS=$ts|DEL=$del|CLR=$color|BRI=$br|dBm=$rssi");

}
Fwsocket::close_wlisten_socket();
Fwsocket::destroy_wlisten_socket();
Flog::close_wlog();
