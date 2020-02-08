package Fparse;


my $WCLI_PREFIX = "wclient";

sub get_ident {
  my ($string) = @_;

  my ($ltime,$ident,$status,$loop) = split '~',$string;
  #print $status;
  my ($hostname,$client,$par1,$par2) = split /\|/,$ident;
  #my ($tmp_cliname,$tmp_clinum) = split '-',$client;
  #if($tmp_cliname eq $WCLI_PREFIX){
  #}
  return $client;
}

sub get_ident_cli {
  my ($string) = @_;
  if(length($string) < 30){
    return undef,undef,undef;
  }
  my ($ltime,$ident,$status,$loop) = split '~',$string;
  if(!defined($ltime)) {return undef,undef,undef;}
  if(!defined($ident)) {return undef,undef,undef;}
  if(!defined($status)) {return undef,undef,undef;}
  if(!defined($loop)) {return undef,undef,undef;}

  my ($hostname,$client,$ctime,$nl_flag) = split /\|/,$ident;
  $ltime = substr $ltime,1,length($ltime)-2;
# print "$hostname $client L=$ltime C=$ctime \n";
  return $hostname,$client,$ltime-$ctime;
}

sub get_ident_srv {
  my ($string) = @_;
  if(length($string) < 30){
    return undef,undef,undef,undef;
  }
  my ($ltime,$ident,$status,$com) = split '~',$string;
  if(!defined($ltime)) {return undef,undef,undef,undef;}
  if(!defined($ident)) {return undef,undef,undef,undef;}
  if(!defined($status)) {return undef,undef,undef,undef;}
  if(!defined($com)) {return undef,undef,undef,undef;}

  my ($hostname,$client,$cli_count,$mode_flag) = split /\|/,$ident;
  $ltime = substr $ltime,1,length($ltime)-2;
  $cli_count = substr $cli_count,4,length($cli_count)-4;
  my $mode = substr $mode_flag,4,length($mode_flag)-4;
  return $hostname,$client,$cli_count,$mode,$ltime;
}


sub get_loop_status_cli {
  my ($string) = @_;
  my ($ltime,$ident,$status,$loop) = split '~',$string;
  my ($loop_no_id,$last_com,$com,$com_hist,$vol,$film,$film_pos,$pin_status,$projector_status,$projector_return,$projector_msg) = split /\|/,$loop;
  # print $loop."\n";
  my ($loop_type,$loop_no) = split '=',$loop_no_id;
  $last_com = substr $last_com,4,length($last_com)-4;
  $com = substr $com,4,length($com)-4;
  $com_hist = substr $com_hist,4,length($com_hist)-4;
  $vol = substr $vol,4,length($vol)-4;
  $film = substr $film,4,length($film)-4;
  $film_pos = substr $film_pos,4,length($film_pos)-4;
  $pin_status = substr $pin_status,4,length($pin_status)-4;
  $projector_status = substr $projector_status,4,length($projector_status)-4;
  $projector_return = substr $projector_return,4,length($projector_return)-4;
  my($projector,$msg) = split ':',$projector_msg;
  $projector = substr $projector,4,length($projector)-4;
  #print "$loop_type $loop_no $last_com $com $vol $msg\n";
  return $loop_type,$loop_no,$last_com,$com,$com_hist,$vol,$film,$film_pos,$pin_status,$projector_status,$projector_return,$projector,$msg;
}

sub get_loop_status_srv {
  my ($string) = @_;
  my ($ltime,$ident,$status,$loop) = split '~',$string;
  my ($cflag,$last_com,$com,$com_hist,$vol_msg) = split /\|/,$loop;
  # print $loop."\n";
  $last_com = substr $last_com,4,length($last_com)-4;
  $com = substr $com,4,length($com)-4;
  $com_hist = substr $com_hist,4,length($com_hist)-4;
  my ($cfl,$cflag_num) = split '=',$cflag;
  my ($vol,$msg) = split ':',$vol_msg;
  $vol = substr $vol,4,length($vol)-4;
#  print "$loop_type $loop_no $last_com $com $com_hist $vol $msg\n";
  return $cflag_num,$last_com,$com,$com_hist,$vol,$msg;
}

sub get_status_cli_srv {
  my ($string) = @_;
  my ($ltime,$ident,$status,$loop) = split '~',$string;
  my ($temp,$thro,$volt) = split /\|/,$status;
  $temp = substr $temp,4,length($temp)-4;
  $thro = substr $thro,7,length($thro)-7;
  $volt = substr $volt,4,length($volt)-4;
  return $temp,$thro,$volt;
}


sub print_hash {
  my ($hash) = @_;
  foreach my $key (keys %$hash){
    print $key."=====> \n";
    print $hash->{"$key"}->{'hostname'}."\n";
    print $hash->{"$key"}->{'name'}."\n";
    print $hash->{"$key"}->{'delay'}."\n";
    print $hash->{"$key"}->{'com'}."\n";
    print $hash->{"$key"}->{'msg'}."\n";
    print $hash->{"$key"}->{'loop_type'}."\n";
    print $hash->{"$key"}->{'loop_no'}."\n";
    print @{$hash->{"$key"}->{'last_com'}};
    print "\n\n";

  }
}

sub parse_wresp {
  my ($str) = @_;
  my ($cli_num,$wip,$status,$ccomm,$ts,$color,$br,$rssi) = split /\|/,$str;
  my $cli_name = $WCLI_PREFIX."-".$cli_num;
  my $lts = time();
  #my $del = $lts - $ts;
  my $del = "un";
  return $cli_num,$cli_name,$wip,$status,$ccomm,$ts,$del,$color,$br,$rssi;
}


sub get_status_wdata {
  my ($line) = @_;
  my ($ltime,$ident,$loop) = split '~',$line;
#  print "$ltime $ident $loop\n";
  if(!defined($ltime)) {return undef,undef,undef,undef,undef,undef;}
  if(!defined($ident)) {return undef,undef,undef,undef,undef,undef;}
  if(!defined($loop)) {return undef,undef,undef,undef,undef,undef;}

  my ($lip,$wcname,$wip,$par1) = split /\|/,$ident;
  my ($status,$com,$par2,$par3,$clr,$bri,$rssi) = split /\|/,$loop;

  #print "$wcname $wip $status $com $clr $bri $rssi\n";
  return $wcname,$wip,$status,$com,$clr,$bri,$rssi;
}
1;
