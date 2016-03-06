#!/usr/bin/perl

#
# myremainder.pl
#
# Developed by Dinesh D <dinesh@exceleron.com>
# Copyright (c) 2015 Exceleron Software, LLC.
# All rights reserved.
#
# Changelog:
# 2015-07-01 - created
#

use strict;
use warnings;
use Tie::File;
use Data::Dumper;

unless($ARGV[0]){
    die "Pass an argument\n\tnow - to get current remainder\n\tlist - to list all remainder\n\tcreate - to create a new remainder\n";
}

my $remainder_file = "myreminder.list";
my $option = lc($ARGV[0]);
my $week_day = [qw/sun mon tue wed thu fri sat/];

my (undef,$min,$hour,$mday,$mon,$year,$wday) = localtime;

$mon = $mon + 1;
$year = int("20" . ($year % 100));

my $time_now = "$year:$mon:$mday:$hour:$min";

tie my @array, 'Tie::File', $remainder_file or die $@;

if($option eq 'now'){
    $ENV{DISPLAY} = ':0';
    my $index = 0;
    foreach my $remainder (@array) {

        my ($time,$title,$detail) = split('\|',$remainder);

        if($time){
            my ($year_t,$mon_t,$mday_t,$hour_t,$min_t) = split(":",$time);
            $year_t = $year unless($year_t);
            $mon_t = $mon unless($mon_t);
            $mday_t = $mday unless($mday_t);
            $hour_t = $hour unless($hour_t);
            $min_t = $min unless($min_t);
            $time = "$year_t:$mon_t:$mday_t:$hour_t:$min_t";
        }
        else{
            $time = $time_now;
        }

        if($time eq $time_now){

            # if title is not available, which means only 2 arguments passed
            unless($detail){
                $detail = $title;
                $title = "DD Remainder";
            }

            # we have time but we dont have any other details
            $title = "DD Remainder" unless($title);

            if(system("notify-send","-u","critical","$title","$detail") == 0){
                splice @array, $index, 1;
                $index--;
            }
        }

        $index++;
    }
}
elsif($option eq 'list'){
    print Dumper \@array;
}
elsif($option eq 'create'){

    unless($ARGV[1]){
        print "Argument for create should be 'yyyy:m:d:D:h:m'|'title'|'details'\n";
        print "Title is optional\n";
        print "Date can be set only whatever is required. eg: ::::5: will execute at next 5 AM\n";
        die;
    }

    push @array, $ARGV[1];
}

untie @array;            # all finished
