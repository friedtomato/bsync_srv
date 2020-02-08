#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::UNIX;
use GUI;


$| = 1;
print ">";
while(<>){
  my $cli = IO::Socket::UNIX->new (
	Type 	=> SOCK_STREAM,
	Peer	=> '/tmp/bsyncsrvsock'
  ) or die "can't do: $!\n";
  print ">";
  chomp $_;	
  $cli->send($_);
  $cli->close();
}

