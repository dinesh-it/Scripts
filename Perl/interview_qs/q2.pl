#!/usr/bin/perl

# Changelog:
# 2022-03-11 - created
#
# Palindrome Permutation: Given a string, write a function to check if it 
# is a permutation of a palindrome. A palindrome is a word or phrase that
# is the same forwards and backwards. A permutation is a rearrangement of 
# letters. The palindrome does not need to be limited to just dictionary words.
# EXAMPLE
# Input: Tact Coa
# Output: True (permutations: "taco cat", "atco eta", etc.)

use strict;
use warnings;

my $inp = $ARGV[0];
my $oc = 0;
foreach (split('', $inp)) {
    next if($_ eq ' ');
    my $c = () = $inp =~ /$_/ig;
    $oc++ if($c%2 == 1);
    last if($oc > 1);
}

if($oc > 1) {
    print "$inp - False\n";
}
else {
    print "$inp - True\n";
}

