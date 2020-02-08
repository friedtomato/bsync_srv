#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::UNIX;



$| = 1;

my $filename = $ARGV[0];

open FCOM, "<",$filename or die "[file_cli]: cannot open $filename $!";
my $END_OF_LINE = 0;

my $num_loops = <FCOM>;
chomp $num_loops;
my $count_loops = 0;
while(!$END_OF_LINE){
	while(my $cmd = <FCOM>){
  		my $cli = IO::Socket::UNIX->new (
			Type 	=> SOCK_STREAM,
			Peer	=> '/tmp/bsyncsrvsock'
	  	) or die "[file_cli]: can't open socket /tmp/bsyncsrcsock: $!\n";
  		chomp $cmd;	
	  	$cli->send($cmd);
  		my $resp;
	  	$cli->recv($resp,32);
  		print "received $resp\n";
	  	$cli->close();
	}
	seek FCOM,0,0;
	$num_loops = <FCOM>;
	chomp $num_loops;
	$count_loops++;
	if($count_loops == $num_loops){
		$END_OF_LINE = 1;
	}
}

