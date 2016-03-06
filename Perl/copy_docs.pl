#!/usr/bin/perl

#
# copy_docs.pl
#
# Developed by Dinesh D <dinesh@exceleron.com>
# Copyright (c) 2016 Exceleron Software, LLC.
# All rights reserved.
#
# Changelog:
# 2016-03-06 - created
#

use strict;
use warnings;
use File::Find;
use File::Path qw(make_path);
use File::Copy qw(copy);
use Data::Dumper;


if(@ARGV < 2){
    die "Usage: copy_docs.pl source_root_dir dest_root_dir reg_ex_str (optional)\n";
}

my $source_root_dir = $ARGV[0];
my $dest_root_dir = $ARGV[1];
my $doc_ext_match = $ARGV[2] || '\.(doc)x?|(ppt)x?|(pdf)$';

unless( -d $dest_root_dir ){
    print "Trying to create root dir $dest_root_dir since its not available\n";
    make_path($dest_root_dir) or die "Failed to create dir: $dest_root_dir , Error: $!\n";
}

find({ wanted => \&process_file, no_chdir => 1 }, $source_root_dir);
my $modules;

sub process_file {
    my $file_name = $_; 
    if (-f $file_name and $file_name =~ m/$doc_ext_match/ ) {
        my $new_file_name = $file_name;

        # Convert filenames to relative file paths
        $new_file_name =~ s/$source_root_dir//;

        # Convert all / in the path to _ to make uniq file name
        $new_file_name =~ s/\//_/g;

        # Add dest_root_dir to the new file name
        $new_file_name = $dest_root_dir . '/' . $new_file_name;

        # Don't overwrite if the file already exist
        return  print "Skipping file: $new_file_name, file already exist\n" if( -e $new_file_name);

        copy($file_name, $new_file_name) or return print "Failed to copy $new_file_name, Error: $!\n"; 
        print "Copied: $new_file_name\n";
    }   
}

