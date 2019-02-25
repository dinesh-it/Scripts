#!/usr/bin/perl

#
# Developed by Dinesh D
#
# Script to get the filtered, needed car from the Zoomcar daily deals page
# Please refer https://www.zoomcar.com/bangalore/deals page for deals and 
# this script is working based on the result from this page, so if that page 
# not working or modified, obviously this script is no use.
#
# Example Usage for this script:
# Lets say we want to see if any car available in the bangalore south region 
# with 240 or more free km with 12 h usage time and offer price less than 1500 rs. 
# Then following will give the result
#
# perl zoomcar_deals.pl --city=bangalore --zone=south --km=240 --fare=1500 --time=12

use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use Getopt::Long;

# This URL is for Bangalore
my $url = 'https://www.zoomcar.com/deals/filtered_active_deals?platform=web&api_version=v3&sort=1&';

my $city_zone;
my $discount_needed = 10;
my $km_needed = 10;
my $date_needed = ' ';
my $duration_needed = 4;
my $fare_needed = 10000;
my $city = 'bangalore';
my $help = 0;
my $all = 0;

GetOptions (
    "discount=i" => \$discount_needed,
    "time=i" => \$duration_needed,
    "km=i" => \$km_needed,
    "date=i" => \$date_needed,
    "fare=i" => \$fare_needed,
    "zone=s" => \$city_zone,
    "city=s" => \$city,
    "help" => \$help,
    "all" => \$all,
);

if($all) {
    $discount_needed = 0;
    $km_needed = 0;
    $duration_needed = 0;
    $fare_needed = 10000000;
    print "Listing all available cars\n";
}

if($help) {
    print "A helper script to check zoomcar daily deals\n";
    print "Options will do and checks, so you will get result only if all conditions matched\n";
    print "--discount=[int] -> get cars with minimum discount value - default 10\n";
    print "--time=[int]     -> Time in hours to get cars with minimum that many hours available in deals - default 4\n";
    print "--km=[int]       -> Minimum km should avalable in deal - default 10\n";
    print "--fare=[int]     -> Discount fare lesser than this - default 10000\n";
    print "--date=[int]     -> Integer date value, eg: 01, 25, 30\n";
    print "--zone=[string]  -> It can be east, west, central, south or north\n";
    print "--city=[string]  -> It can be bangalore or chennai defaults to bangalore\n";
    print "--all            -> List all the available cars\n";
    print "--help           -> Prints this help and exits\n";
    print "Defaults: $discount_needed, $duration_needed, $km_needed, $fare_needed respectively\n";
    exit;
}

my $zones = {
    bangalore => {
        west => 5,
        east => 4,
        central => 3,
        south => 2,
        north => 1,
    },
    chennai => {
        central => 21,
        west => 19,
        south => 18
    },
};

$url .= "city=$city&";

if($city_zone and !$zones->{$city}{$city_zone}) {
    die "Invalid zone value\n";
}
elsif($city_zone) {
    $url .= 'zone=' . $zones->{$city}{$city_zone};
}


my $ua = LWP::UserAgent->new;

my $resp = $ua->get($url);

if(!$resp->is_success) {
    die "Failed to fetch data\n";
}

my $cars = decode_json($resp->decoded_content);

if(!$cars or ref $cars ne 'ARRAY') {
    die "Invalid response received\n";
}


my $count = 0;
my $filtered_count = 0;
foreach my $car (@{$cars}) {
    next if($car->{sold_out});

    $count++;

    $car->{discount} =~ /^(\d+)/;
    my $discount = $1;
    my $duration = $car->{duration};
    my $car_name = $car->{car};
    my $for_date = $car->{starts_date} . ' ' . $car->{starts_time};
    my $print_location = 0;


    foreach my $price (@{$car->{pricing}}) {
        $price->{kms} =~ /^(\d+)/;
        my $kms = $1;

        if($discount >= $discount_needed 
            && $duration >= $duration_needed 
            && $kms >= $km_needed 
            && $price->{discounted_fare} <= $fare_needed
            && $car->{starts_date} =~ /$date_needed/) {
            print "\n$car_name for $duration h on $for_date - ";
            print "$price->{discounted_fare} Rs ($price->{kms} km)";
            $print_location = 1;
        }
    }

    if($print_location) {
        print " At: ";
        foreach my $loc (@{$car->{location}}) {
            print "$loc->{name}, ";
        }
        print "\n";
        $filtered_count++;
    }
}

print "\n$filtered_count cars filtered from $count total available cars\n";
