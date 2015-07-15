#!/usr/bin/perl -w
use strict; 
use warnings;
use File::Find;
use Term::ANSIColor;
use File::Slurp;
use MP3::Info;
use Digest::MD5 qw(md5_hex);

my $dir = $ARGV[0];
our $ip = $ARGV[1];
our $op = $ARGV[2] || '';
my $count = 0;

if(!$ARGV[0]){
	print "Arguments are: \n\tdirectory_path \n\tinput_file_name_pattern_to_match \n\toutput_file_name_pattern_to_change\n";
	exit;
}
find({ wanted => \&process_file, no_chdir => 1 }, $dir);
if( $count > 0 ){
	cprint("$count file(s) renamed successfully\n","bright_red");
}else {
	cprint("No Changes to file(s)\n","blue");
}

sub cprint
{
	my ($str, $color, $no_new_line) = @_;
	$str = $str . "\n" if (!$no_new_line);
	print color($color) . "$str"; 
	print color("reset");
}


sub process_file {
	if (-f $_ and $_ =~ /\.mp3$/) {
		my $oldfile = $_;
		$oldfile =~ s/\.[mM][pP]3$//gi;
		$oldfile =~ m/^(.+)\/(.+)$/;
		my ($dir,$file) = ($1,$2) if($1 and $2); 
		if($file =~ m/$ip/){

			$oldfile = "$oldfile.mp3" if( $oldfile !~ /.jp[eg|g]$/i);
			$file =~ s/$ip/$op/gix;
			my $newfile = "$dir/$file.mp3";

			if(not -e "$newfile" and $newfile !~ /^\s*$/){
				if((rename "$oldfile","$newfile") == 1){
					cprint("Renamed from $oldfile to $newfile\n" , "green");
					$count = $count + 1;
				}
				else {
					cprint("ERROR: Rename at file $oldfile\n" , "red");
				}
			}
			else {
				#remove_if_dup($oldfile,$newfile);
				cprint("ERROR: File $newfile already exist\n" , "yellow");
			}
		}
	}
}

sub remove_if_dup {
	my ($newfile,$oldfile) = @_;
	#my $newhash = get_hash(get_audio($newfile));
	#my $oldhash = get_hash(get_audio($oldfile));
	#print "$newhash $oldhash\n";
	#if($newhash eq $oldhash){
		if((unlink "$newfile") == 1){
			cprint("DUP REMOVED: $newfile\n", "cyan");
		}
		#}
		#else {
		#}
}

sub get_audio {
	my $filename = $_[0] || return;
	my $info = get_mp3info($filename);
	my $audio;
	open(MP3, $filename);
	read(MP3, $audio, $info->{SIZE}, $info->{OFFSET});
	close(MP3);
	return $audio;
}

sub get_hash {
	my $data = $_[0] || return;
	return md5_hex($data);
}
