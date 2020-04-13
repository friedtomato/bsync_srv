#!/usr/bin/perl

use warnings;
use Curses;
use Fparse;
use Header;
use Fsocket;

my $SIG_QUIT = 0;
$SIG{INT} = \&ctrl_c_handler;


sub ctrl_c_handler {
  $SIG_QUIT = 1;
}

my $END_GUI = 0;
my $NLOG_FNAME = "nlog";
my $NLOG_DNAME = $Header::FL_DNAME;
# number of last commands in the array 
my $LAST_COM_QUEUE = 5;
my $TERM_COL;
my $TERM_ROW;
my $NUM_CLI = $Header::NUM_CLI + 1;
my $END_OF_GUI = 0;


initscr;
if(has_colors == 0){ 
  die "no colors\n";
}
curs_set(0);
cbreak;
noecho;
#halfdelay(1);
nodelay(stdscr,1);
keypad(1);
getmaxyx(stdscr, $TERM_ROW, $TERM_COL);
start_color();
init_pair 1,COLOR_GREEN,COLOR_BLACK;
init_pair 2,COLOR_WHITE,COLOR_BLACK;
init_pair 3,COLOR_YELLOW,COLOR_BLACK;
init_pair 4,COLOR_RED,COLOR_BLACK;
init_pair 5,COLOR_CYAN,COLOR_BLACK;

my $cmd_win = new Curses;
$cmd_win = newwin(3,$TERM_COL,$TERM_ROW-3,0);
##$win->addstr(4,4,"hey");
##$win->refresh();
##printw("helloooo");
##refresh;

open LOG,"<$NLOG_DNAME/$NLOG_FNAME" or die "Cannot open nlog ($NLOG_DNAME/$NLOG_FNAME): $!\n";

my $size = -s $NLOG_DNAME."/".$NLOG_FNAME;
my $hclient_status;
my $num_cli_up = 0;
my $num_wcli_up = 0;
my $ch;
my $cmd_string;
my $cmd_trigger = 0;
my $ord = -1;
my $len = -1;
my $gui_status = "un";
my $loop = 0;
my $wifi_client_flag = 1;
while(!$END_OF_GUI){
	$gui_status = "loop";
	$loop++;
	$ch = getch();
	if($ch ne ERR){
		$len = length($ch);
		$ord = ord($ch);
		#$cmd_string = $cmd_string."l=$len|o=$ord";
		if($ord == 10){ # enter
			$cmd_trigger = 1;
			Fsocket::send_cmd($cmd_string);
			#clear();

		}
		elsif (($ord == 50) and ($ch ne '2')){ # backspace
			if(length($cmd_string) > 0){
				$cmd_string = substr $cmd_string,0,length($cmd_string)-1;
			}
		}
		else{
			$cmd_string = $cmd_string.$ch;
			$cmd_trigger = -1;
		}
	}
	else{
#		$cmd_trigger = $cmd_trigger;
	}

	while (my $line = <LOG>){
		$wifi_client_flag = 0;
		$gui_status = "read";
		my $station_type = "un";
		#print $line;
		my $cli_name = Fparse::get_ident($line);
		if(!defined($cli_name)){
			next;
		}
		my $cli_hostname = "un";
		my $cli_count = "un";
		my $mode_flag = "un";
		my $delay = "un";
		my $ltime = "un";
		my $wcli_ip = "un";
		my $wcli_status = "un";
		my $wcli_com = "un";
		my $wcli_name = "un";
		my $wcli_clr = "un";
		my $wcli_bri = "un";
		my $wcli_rssi = "un";
		my $temp = "un";
		my $thro = "un";
		my $volts = "un";
		# server
		if ($cli_name eq $Header::CLI_NAME){
			($cli_hostname,$cli_name,$cli_count,$mode_flag,$ltime) = Fparse::get_ident_srv($line);
			if((!defined($cli_hostname)) or (!defined($cli_name)) or (!defined($cli_count)) or (!defined($mode_flag)) or (!defined($ltime))){
				next;
			}
			($temp,$thro,$volts) = Fparse::get_status_cli_srv($line);
			if((!defined($temp)) or (!defined($thro)) or (!defined($volts))){
				print "undefined temp=$temp / thro=$thro / volts=$volts for $cli_name\n";
				next;
			}
		}
		#clients 
		else{
			# wifi clients
			if((substr $cli_name,0,1) eq 'w'){
				$wifi_client_flag = 1;
				($wcli_name,$wcli_ip,$wcli_status,$wcli_com,$wcli_clr,$wcli_bri,$wcli_rssi) = Fparse::get_status_wdata($line);
				if((!defined($wcli_ip)) or (!defined($wcli_status)) or (!defined($wcli_com)) or (!defined($wcli_name)) or (!defined($wcli_clr)) or (!defined($wcli_bri)) or (!defined($wcli_rssi))){
					next;
				}

			}
			# eth clients
			else{
				($cli_hostname,$cli_name,$delay) = Fparse::get_ident_cli($line);
				if((!defined($cli_hostname)) or (!defined($cli_name)) or (!defined($delay))){
					next;
				}
				($temp,$thro,$volts) = Fparse::get_status_cli_srv($line);
				if((!defined($temp)) or (!defined($thro)) or (!defined($volts))){
					print "undefined temp=$temp / thro=$thro / volts=$volts for $cli_name\n";
					next;
				}
			}
		}
		# check if the line is empty, if yes, go to next (returned by mpv)
		my $srv_win_height = 24;
		my $cli_win_height = 18;
		my $wcli_win_height = 8;
		if(!defined($hclient_status->{"$cli_name"})){
			my $win = new Curses;
			if($cli_name eq $Header::CLI_NAME){
				$win = newwin($srv_win_height,int($TERM_COL/$NUM_CLI),1,1);
				$hclient_status->{"$cli_name"}->{'ctype'} = "srv";
				$station_type = "srv";
				$hclient_status->{"$cli_name"}->{'win'} = $win;
				$hclient_status->{"$cli_name"}->{'hostname'} = $cli_hostname;
				$hclient_status->{"$cli_name"}->{'name'} = $cli_name;
			}
			else{
				# window for wifi clients
				if($wifi_client_flag){
					my ($cn,$cli_index) = split '-',$cli_name;
					$win = newwin($wcli_win_height,int($TERM_COL/$NUM_CLI),$cli_win_height+2,(($cli_index-1) * int($TERM_COL/$NUM_CLI))+1);
					$hclient_status->{"$cli_name"}->{'ctype'} = "wcli";
					$station_type = "wcli";
					$hclient_status->{"$cli_name"}->{'win'} = $win;
				}
				# window for eth clients
				else{
					my ($cn,$cli_index) = split '-',$cli_name;
					$win = newwin($cli_win_height,int($TERM_COL/$NUM_CLI),1,(($cli_index-1) * int($TERM_COL/$NUM_CLI))+1);
					$hclient_status->{"$cli_name"}->{'ctype'} = "cli";
					$station_type = "cli";
					$hclient_status->{"$cli_name"}->{'win'} = $win;
					$hclient_status->{"$cli_name"}->{'hostname'} = $cli_hostname;
					$hclient_status->{"$cli_name"}->{'name'} = $cli_name;
				}
			}
			# count num of clients being up - wifi and eth
			if($wifi_client_flag){
				$num_wcli_up++;
			}
			else{
				$num_cli_up++;
			}
			#print "adding $cli_name\n";
		}
		else{
			$station_type = $hclient_status->{"$cli_name"}->{'ctype'};
		}
		
		#server
		if(($station_type eq "cli") or ($station_type eq "srv")){
			$hclient_status->{"$cli_name"}->{'hostname'} = $cli_hostname;
			$hclient_status->{"$cli_name"}->{'cli_count'} = $cli_count;
			$hclient_status->{"$cli_name"}->{'mode_flag'} = $mode_flag;
			$hclient_status->{"$cli_name"}->{'delay'} = $delay;
			$hclient_status->{"$cli_name"}->{'ltime'} = $ltime;
			$hclient_status->{"$cli_name"}->{'temp'} = $temp;
			$hclient_status->{"$cli_name"}->{'thro'} = $thro;
			$hclient_status->{"$cli_name"}->{'volts'} = $volts;
		}
		my $loop_type = "un";
		my $loop_no = "un";
		my $last_com = "un";
		my $cflag_num = "un";
		my $com = "un";
		my $volume = "un";
		my $film = "un";
		my $film_pos = "un";
		my $pin_status = "un";
		my $projector_status = "un";
		my $projector_return = "un";
		my $projector = "un";
		my $msg = "un";
		my $cli = "un";
		my $com_hist = 0;

		# server
		if ($station_type eq "srv"){
			($cflag_num,$last_com,$com,$com_hist,$volume,$msg) = Fparse::get_loop_status_srv($line);
			if((!defined($cflag_num)) or (!defined($last_com)) or (!defined($com)) or (!defined($volume)) or (!defined($com_hist)) or (!defined($msg))){
				next;
			}
		}
		# clients
		else{
			# this shall be done only for eth clients
			if($station_type eq "cli"){
				($loop_type,$loop_no,$last_com,$com,$com_hist,$volume,$film,$film_pos,$pin_status,$projector_status,$projector_return,$projector,$msg) = Fparse::get_loop_status_cli($line);
				if((!defined($loop_type)) or (!defined($loop_no)) or (!defined($last_com)) or (!defined($com)) or (!defined($volume)) or (!defined($film)) or (!defined($projector_status))){
					next;       
				}
				if((!defined($projector_return)) or (!defined($projector)) or (!defined($msg)) or (!defined($pin_status)) or (!defined($film_pos)) or (!defined($com_hist))){
					next;
				}
			}
		}

		if(($station_type eq "srv") or ($station_type eq "cli")){
			if(!defined($hclient_status->{"$cli_name"}->{'cmdhist'}->{"$com"})){
				$hclient_status->{"$cli_name"}->{'cmdhist'}->{"$com"} = 1;
			}
			else{
				$hclient_status->{"$cli_name"}->{'cmdhist'}->{"$com"}++;
			}
		
			$hclient_status->{"$cli_name"}->{'last_com'} = $last_com;
			$hclient_status->{"$cli_name"}->{'com'} = $com;
			$hclient_status->{"$cli_name"}->{'vol'} = $volume;
			$hclient_status->{"$cli_name"}->{'msg'} = $msg;
			$hclient_status->{"$cli_name"}->{'loop_type'} = $loop_type;
			$hclient_status->{"$cli_name"}->{'loop_no'} = $loop_no;
			$hclient_status->{"$cli_name"}->{'cflag_num'} = $cflag_num;
			$hclient_status->{"$cli_name"}->{'prj_status'} = $projector_status;
			$hclient_status->{"$cli_name"}->{'prj_return'} = $projector_return;
			$hclient_status->{"$cli_name"}->{'prj'} = $projector;
			$hclient_status->{"$cli_name"}->{'film'} = $film;
			$hclient_status->{"$cli_name"}->{'film_pos'} = $film_pos;
			$hclient_status->{"$cli_name"}->{'pin'} = $pin_status;
			$hclient_status->{"$cli_name"}->{'run_com_hist'}->{"$com"} = $com_hist;
		}
		if($station_type eq "wcli"){
			$hclient_status->{"$cli_name"}->{'wip'} = $wcli_ip;
			$hclient_status->{"$cli_name"}->{'wstatus'} = $wcli_status;
			$hclient_status->{"$cli_name"}->{'wcom'} = $wcli_com;
			$hclient_status->{"$cli_name"}->{'wclr'} = $wcli_clr;
			$hclient_status->{"$cli_name"}->{'wbri'} = $wcli_bri;
			$hclient_status->{"$cli_name"}->{'wrssi'} = $wcli_rssi;
		}

		if(($station_type eq "srv") and ($com eq "checkin")){
			$hclient_status->{"$cli_name"}->{'cli'} = $msg;
		}
		foreach my $key (sort {$a cmp $b} keys %$hclient_status){
			
			my $cur_command = "un";
			my $last_command = "un";
			my $cur_comm_num = 0;
			my $last_comm_num = 0;
			my $run_com_hist_cur = 0;
			my $run_com_hist_last = 0;

			my $tmp_win = $hclient_status->{"$key"}->{'win'};

			if(($hclient_status->{"$key"}->{'ctype'} eq "srv") or ($hclient_status->{"$key"}->{'ctype'} eq "cli")){
				$cur_command = $hclient_status->{"$key"}->{'com'};
				if(!defined($cur_command)){ $cur_command = "fail";}
				$last_command = $hclient_status->{"$key"}->{'last_com'};
				if(!defined($last_command)){ $last_command = "fail";}
				$cur_comm_num = $hclient_status->{"$key"}->{'cmdhist'}->{"$cur_command"};
				if(!defined($cur_comm_num)){ $cur_comm_num = "fail";}
				$last_comm_num = $hclient_status->{"$key"}->{'cmdhist'}->{"$last_command"};
				if(!defined($last_comm_num)){ $last_comm_num = "fail";}
				$run_com_hist_cur = $hclient_status->{"$key"}->{'run_com_hist'}->{"$cur_command"};
				if(!defined($run_com_hist_cur)){ $run_com_hist_cur = "fail";}
				$run_com_hist_last = $hclient_status->{"$key"}->{'run_com_hist'}->{"$last_command"};
				if(!defined($run_com_hist_last)){ $run_com_hist_last = "fail";}
			}
			# server
			if($hclient_status->{"$key"}->{'ctype'} eq "srv"){
				$tmp_win->attron(COLOR_PAIR(1));
				$tmp_win->attron(A_BOLD);
				$tmp_win->addstr(1,1,"HNA:".$hclient_status->{"$key"}->{'hostname'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(2,1,"COM:".$hclient_status->{"$key"}->{'com'}."[$run_com_hist_cur]");
				$tmp_win->clrtoeol();
				$tmp_win->addstr(3,1,"LCO:".$hclient_status->{"$key"}->{'last_com'}."[$run_com_hist_last]");
				$tmp_win->clrtoeol();
				$tmp_win->addstr(4,1,"VOL:".$hclient_status->{"$key"}->{'vol'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(5,1,"NCL:".$hclient_status->{"$key"}->{'cli_count'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(6,1,"MOD:".$hclient_status->{"$key"}->{'mode_flag'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(7,1,"TST:".$hclient_status->{"$key"}->{'ltime'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(8,1,"TMP:".$hclient_status->{"$key"}->{'temp'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(9,1,"THR:".$hclient_status->{"$key"}->{'thro'});
				$tmp_win->clrtoeol();
				$tmp_win->addstr(10,1,"VTS:".$hclient_status->{"$key"}->{'volts'});
				$tmp_win->clrtoeol();

				$tmp_win->addstr(11,1,"CLI:");
				$tmp_win->clrtoeol();
				my $line = 11;
				for(my $i=$line;$i<$Header::NUM_CLI+$line;$i++){
					$tmp_win->addstr($i,5," ");
					$tmp_win->clrtoeol();
				}
				if($hclient_status->{"$key"}->{'cli_count'} ne "0/".$Header::NUM_CLI){
			 		foreach my $key (split ',',$hclient_status->{"$key"}->{'cli'}){
						if($key ne ""){
							$tmp_win->addstr($line,5,$key);
							$tmp_win->clrtoeol();
							$line++;
						}	
					}
				}

				box($tmp_win,0,0);
				$tmp_win->addstr(0,2,"[$key]");
				$tmp_win->attroff(A_BOLD);
				$tmp_win->attroff(COLOR_PAIR(1));
				$tmp_win->refresh();
			}
			# clients
			else{
				# wifi clients
				if($hclient_status->{"$key"}->{'ctype'} eq "wcli"){
					$tmp_win->attron(COLOR_PAIR(5));
					$tmp_win->addstr(1,1,$hclient_status->{"$key"}->{'wip'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(2,1,$hclient_status->{"$key"}->{'wcom'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(3,1,$hclient_status->{"$key"}->{'wstatus'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(4,1,$hclient_status->{"$key"}->{'wclr'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(5,1,$hclient_status->{"$key"}->{'wbri'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(6,1,$hclient_status->{"$key"}->{'wrssi'});
					$tmp_win->clrtoeol();

					box($tmp_win,0,0);
					$tmp_win->addstr(0,2,"[$key]");
					$tmp_win->attroff(COLOR_PAIR(5));
					$tmp_win->refresh();

				}
				# eth clients
				else{

					if($hclient_status->{"$key"}->{'loop_type'} eq "L"){
						$tmp_win->attron(COLOR_PAIR(4));
					}
					elsif($hclient_status->{"$key"}->{'loop_type'} eq "S"){
						$tmp_win->attron(COLOR_PAIR(2));
					}
					$tmp_win->addstr(1,1,"HNA:".$hclient_status->{"$key"}->{'hostname'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(2,1,"COM:".$hclient_status->{"$key"}->{'com'}."[$run_com_hist_cur]");
					$tmp_win->clrtoeol();
					$tmp_win->addstr(3,1,"LCO:".$hclient_status->{"$key"}->{'last_com'}."[$run_com_hist_last]");
					$tmp_win->clrtoeol();
					$tmp_win->addstr(4,1,"VOL:".$hclient_status->{"$key"}->{'vol'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(5,1,"LOT:".$hclient_status->{"$key"}->{'loop_type'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(6,1,"LON:".$hclient_status->{"$key"}->{'loop_no'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(7,1,"DEL:".$hclient_status->{"$key"}->{'delay'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(8,1,"FLM:".$hclient_status->{"$key"}->{'film'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(9,1,"FPO:".$hclient_status->{"$key"}->{'film_pos'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(10,1,"PNA:".$hclient_status->{"$key"}->{'prj'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(11,1,"PST:".$hclient_status->{"$key"}->{'prj_status'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(12,1,"PRE:".$hclient_status->{"$key"}->{'prj_return'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(13,1,"PIN:".$hclient_status->{"$key"}->{'pin'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(14,1,"TMP:".$hclient_status->{"$key"}->{'temp'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(15,1,"THR:".$hclient_status->{"$key"}->{'thro'});
					$tmp_win->clrtoeol();
					$tmp_win->addstr(16,1,"VTS:".$hclient_status->{"$key"}->{'volts'});
					$tmp_win->clrtoeol();
					box($tmp_win,0,0);
					$tmp_win->addstr(0,2,"[$key]");
					if($hclient_status->{"$key"}->{'loop_type'} eq "L"){
						$tmp_win->attroff(COLOR_PAIR(4));
					}
					elsif($hclient_status->{"$key"}->{'loop_type'} eq "S"){
						$tmp_win->attroff(COLOR_PAIR(2));
					}
					#$tmp_win->attroff(COLOR_PAIR(2));
				        $tmp_win->refresh();
				}
			}
			#$tmp_win->refresh();
			#print "$key-".$hclient_status->{"$key"}->{'com'}."\n";	

		}
		
		#Parse::print_hash($hclient_status);

	}

	my $tmp_size = -s $NLOG_DNAME."/".$NLOG_FNAME;
	if($tmp_size < $size){
		close LOG;
		open LOG,"<$NLOG_DNAME/$NLOG_FNAME" or die "Cannot open nlog ($NLOG_DNAME/$NLOG_FNAME): $!\n";
		seek LOG,0,0;
		$size = $tmp_size;
		foreach my $key (keys %$hclient_status){
			foreach my $key1 (keys %{$hclient_status->{"$key"}->{'cmdhist'}}){
				$hclient_status->{"$key"}->{'cmdhist'}->{"$key1"} = 0;

			}
		}
	}
	else{
		$size = $tmp_size;
	}

	#cmdline
	$cmd_win->attron(COLOR_PAIR(3));
	if(!defined($cmd_string)){
		$cmd_win->addstr(1,1,"un");
		$cmd_win->clrtoeol();

	}
	else{
		$cmd_win->addstr(1,1,$cmd_string);
	}	
	$cmd_win->clrtoeol();
	box($cmd_win,0,0);
	$cmd_win->addstr(0,2,"CMDLINE[$cmd_trigger|O=$ord|L=$len|GST=$gui_status|LSZ=$size]");
	$cmd_win->attroff(COLOR_PAIR(3));
	$cmd_win->refresh();
	if($cmd_trigger == 1){ # enter has been pressed
		$cmd_string = "";
		$cmd_trigger = 0;
	}
	if ($SIG_QUIT == 1){
		$END_OF_GUI = 1;
	}
}


#$index = 0;
#while(!$END_GUI){
#	getmaxyx(stdscr, $row, $col);
#	$win->addstr(4,4,$col);
#	$win->addstr(4,10,$row);
#	$win->refresh();
#	box($win,0,0);
#	sleep 0.5;
##	$ch = getch();
#	$index = $ch;
#}	

undef $hclient_status;
close LOG;
endwin;

