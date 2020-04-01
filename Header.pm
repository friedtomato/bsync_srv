package Header;

use Sys::Hostname;

#number of clients
$NUM_CLI = 8;
# volume on clients
$VOL_CLI = "50%";
# something
$NGO_CLI = "ngo";

# broadcasts tryouts
$BCAST_COUNTS = 1;

# ------- LOGGING ------------
#$FL_DNAME = "/home/pi/dev/bsync";
$CU_DNAME = $ENV{BSYNC_SCR_PATH};
$FL_DNAME = "$CU_DNAME/log";
$OL_DNAME = $FL_DNAME;
$FL_FNAME = "flog";
$OL_FNAME = "olog";
$WL_FNAME = "wlog";

# ------- hostname identification, PORTs, SOCKETs
$host = hostname();
my ($name,$number) = split '-',$host;
$CLI_NAME = "client-".$number;
$MIP   = '192.168.0.1';
# broadcast on eth
$BPORT = 9999;
# listen on eth
$LPORT = 7777;
# broadcast and listen port on wifi
$WBPORT = 5555;
$WLPORT = 5544;

$COM_SOCKET_PATH = "/tmp/bsyncsrvsock";
$LS_TIMEOUT = 2000;
# --------------------
$END_OF_THE_LINE = 0;

# parameter indicating the mode: manual / automatic
$MODE = "manual";


1;
