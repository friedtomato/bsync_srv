package Fstatus;

use warnings;
use strict;
use Header;


#my $STATUS_DNAME = "/home/pi/bin";
my $STATUS_DNAME = $Header::FL_DNAME;
my $STATUS_FNAME = "status";
my $STATUS_FULL = "$STATUS_DNAME/$STATUS_FNAME";

my @LINE_PARAMS;

sub get_status {
	open(FD,'<',$STATUS_FULL) or die "cannot open $STATUS_FULL: $!\n";
	my $end = 0;
	my $line;
	while(!$end){
		$line = <FD>;
		#print $line."\n";
		if(defined($line) and (length($line) > 100)){
			@LINE_PARAMS = split /\|/,$line;
			$end = 1;
		}
		else{
			seek FD,0,0;
		}

		
	}
	close(FD);
	return $line;
}

sub parse_temp {
	return $LINE_PARAMS[7];
}

sub parse_volts {
	my $core = substr $LINE_PARAMS[1],4,length($LINE_PARAMS[1])-5;
	my $sdrc = substr $LINE_PARAMS[2],4,length($LINE_PARAMS[2])-5;
	my $sdri = substr $LINE_PARAMS[3],4,length($LINE_PARAMS[3])-5;
	my $sdrp = substr $LINE_PARAMS[4],4,length($LINE_PARAMS[4])-5;
	my $total = $core + $sdrc + $sdri + $sdrp;
	$total = "COR=".$total."V";
	return $total;
}

sub parse_thro {
	return $LINE_PARAMS[8];
}
1;
