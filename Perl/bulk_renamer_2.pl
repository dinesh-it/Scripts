#!/usr/bin/perl -w
use strict; 
use warnings;
use File::Find;

my $dir = shift;
our $ip = shift;
our $op = shift || '';
my $count = 0;
find({ wanted => \&process_file, no_chdir => 1 }, $dir);
print "$count files renamed successfully\n";

sub process_file {
    if (-f $_) {
        my $oldfile = $_;
	if($oldfile =~ m/$ip/){
		my $newfile = $oldfile;
		$newfile =~ s/$ip/$op/;
		if((rename "$oldfile","$newfile") == 1){
			print "Renamed from $oldfile to $newfile\n";
			$count = $count + 1;
		}
	}
   }
}
