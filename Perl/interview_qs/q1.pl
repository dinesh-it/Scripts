#!/usr/bin/perl

#
# Changelog:
# 2022-03-10 - created
#

use strict;
use warnings;

#my @inp = qw/1 1 1 0 1 0 1 1 0 1 0 0 0/;
#my @inp = qw/1 0 1 1 1 1 1/;
#my @inp = qw/1 1 0 1 0 1 1 1 1 0/;
my @inp = qw/1 1 1 1 1 1 0 1 0 0 0 0 0 0 0 1 0/;

find_mc(@inp);

#my $mc1 = find_mc(@inp);
#my $mc2 = find_mc(reverse(@inp));

sub find_mc {
    my @inp = @_;

    print "@inp\n";
    my $mc = 0;
    my $oc = 0;
    my $mcb = 0;
    my $ocb = 0;
    for (my $i = 1; $i < scalar(@inp); $i++) {
        if($inp[$i] ne $inp[0]) {
            $oc++;
        }
        elsif($oc > 0) {
            $mc+=$oc;
        }

        if($inp[-$i-1] ne $inp[-1]) {
            $ocb++;
        }
        elsif($ocb > 0) {
            $mcb+=$ocb;
        }
    }

    if($mc > $mcb) {
        print "$mcb moves required other ($mc)\n";
    }
    else {
        print "$mc moves required other ($mcb)\n";
    }
}

#1 1 1 0 1 0 1 1 0 1 0 0 0
#
#fv = 1;
#
#0 - 1 - C = 0, M = 0;
#1 - 1 - C = 0, M = 0;
#2 - 1 - C = 0, M = 0;
#3 - 0 - C = 1, M = 0;
#4 - 1 - C = 1, M = M + C = 1;
#5 - 0 - C = 2, M = 1;
#6 - 1 - C = 2, M = M + C = 3;
#7 - 1 - C = 2, M = M + C = 5;
#8 - 0 - C = 3, M = 5;
#9 - 1 - C = 3, M = M + C = 8;
#10 - 0 - C = 4, M = 8;
#10 - 0 - C = 5, M = 8;
#10 - 0 - C = 6, M = 8;

