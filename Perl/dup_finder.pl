
#!/usr/bin/perl -w
use strict; 
use warnings;
use File::Find;
use Data::Dumper;
use File::Slurp;
use Text::Soundex;
use Digest::SHA1 'sha1_hex';

my $dir = shift || './';
my $pat = shift || '.+'; # pattern for search
my $ip = shift || ''; # pattern for remove duplicates
#my $op = shift || '';
my $count = 0;
my $file_list = {};
my $dup_dir_list = {};
my $dup_file_count = 0;
my $dup_dir_count = 0;
my $removed_count = 0;
find({ wanted => \&process_file, no_chdir => 1 }, $dir);

foreach my $sha_hash (keys ($file_list)){
	if(scalar(@{$file_list->{$sha_hash}} > 1)){
		$dup_file_count = $dup_file_count + scalar(@{$file_list->{$sha_hash}}) - 1;
		print Dumper($file_list->{$sha_hash});
		foreach my $file (@{$file_list->{$sha_hash}}){
			if( $ip ne '' and $file =~ m/$ip/){
				if((unlink "$file") == 1){
					print "REMOVED: $file\n";
					$removed_count = $removed_count + 1;
				}
			}
		}
		#print Dumper($file_list->{$sha_hash}) if($ip eq '');
	}
}

print "********************************************************\n";
print "$count files/dir's traced\n";
print "$dup_dir_count duplicate name directories found\n";
print "$dup_file_count duplicate files found\n";
print "$removed_count duplicate files removed\n";
print "********************************************************\n";
#print Dumper($dup_dir_list);

sub process_file {
	my $file = $_;
	#print "Taking file $file\r\n";
	if( -f $file and $file ne '.' and $file ne '..' ){#and $file =~ m/$pat/ ){
		my $fdata = read_file($file);
		my $hash = sha1_hex($fdata);
		push(@{$file_list->{$hash}}, $file );
		$count = $count + 1;
		local $| = 1;
		print "Processing file: $count\r";
	}
	#elsif(-d $file){
		

=head
		$count = $count + 1;
		if(not defined $dup_dir_list->{uc($file)}){
			$dup_dir_list->{uc($file)} = get_file_count($file); 
			$dup_dir_list->{file} = $file;
		}
		else{
			my $no_files = get_file_count($file);
			print "Duplicate dir : $file with $no_files files\n";
			if($dup_dir_list->{uc($file)} > $no_files){
				$dup_file_count = $dup_file_count + $no_files;
				#unlink "$file";
				print "REMOVED DIR: $file\n";
			}
			else{
				$dup_file_count = $dup_file_count + $dup_dir_list->{uc($file)};
				#unlink "$dup_dir_list->{file}";
				$dup_dir_list->{uc($file)} = get_file_count($file);
                	       	$dup_dir_list->{file} = $file;
				print "REMOVED DIR: $file\n";
			}
			$dup_dir_count = $dup_dir_count + 1;
		}
=cut
#}
}


sub get_file_count {
	my ($file) = @_;
	my $dcount;
	opendir(my $dh, $file) or die "opendir($file): $!";
	while (my $de = readdir($dh)) {
		next if $de =~ /^\./ or $de =~ /config_file/;
		$dcount++;
	}
	closedir($dh);
	return $dcount;
}
