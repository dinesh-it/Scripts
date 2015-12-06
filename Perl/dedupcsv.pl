#!/usr/bin/perl

#
# dedupcsv.pl
#
# Developed by Dinesh D <dinesh@exceleron.com>
#
# Changelog:
# 2015-12-06 - created
#

use strict;
use warnings;
use Text::CSV_XS;
use Data::Dumper;

if(@ARGV < 2){
    die "Pass arguments file_path and unique_column_name\n";
}

my $file = $ARGV[0];
my $uniq_col = $ARGV[1];

# NOTE: We can set an array ref of column order in this variable
# eg: ["one","two","three"]
# Default will take the order of the columns in the file
my $cols_order;

# Will keep the unique records as hasref with uniq col as key
my $uniq_data_as_hash;

# Will keep the duplicate row numbers
my $duplicate_rows = [];

# Get the column names from the first line of the file
my $columns;

# Read all the rows from the csv and store it as arrayref of hashrefs
my $rows = LoadFromCSV([$file]);

#print Dumper(\$rows);
$cols_order = $columns unless($cols_order);

print "The file has " . scalar(@{$rows}) . " rows\n";

my $i = 1;

# remove all duplicate rows which is uniquely identified by $uniq_col
foreach my $row (@{$rows}){

    # Get Uniqueue column value - don't consider symbols(., -_'()) and case
    my $uniq_col_val = lc($row->{$uniq_col});
    $uniq_col_val =~ s/\(.*\)//;
    $uniq_col_val =~ s/[-_\s\.',\(\)]//g;

    if($uniq_data_as_hash->{$uniq_col_val}){

        # Duplicate record
        foreach my $key (keys (%{$row})){

            # Update row only if it has a column value
            if($row->{$key}){
                my $col_val = $row->{$key};

                # for sahana hms
                # $col_val =~ s/\(.*\)// if($key eq "Name" and length($col_val) > 63);

                # Keep data which has more information
                # Ignore if the old record has a data which length is more than the new record
                if(not $uniq_data_as_hash->{$uniq_col_val}->{$key} or length($col_val) > length($uniq_data_as_hash->{$uniq_col_val}->{$key})){
                    $uniq_data_as_hash->{$uniq_col_val}->{$key} = $col_val;
                }
            }
        } 
        push(@{$duplicate_rows}, $i);
    }
    else{

        # New record
        foreach my $key (@{$columns}){
            my $col_val = $row->{$key};

            # for sahana hms
            # $col_val =~ s/\(.+\)//g if($key eq "Name" and length($col_val) > 63);

            $uniq_data_as_hash->{$uniq_col_val}->{$key} = $col_val;
        } 
    }
    $i++;
}

#print Dumper([values %{$uniq_data_as_hash}]);

WriteCSV([values %{$uniq_data_as_hash}], $file . "_uniq.csv ");

print "There are " . scalar(@{$duplicate_rows}) . " duplicate rows removed\n";

# ========================================================================================== #

sub LoadFromCSV
{
    my $files = shift;

    my @rows;
    foreach (@$files) {
        my $csv = Text::CSV_XS->new({binary => 1, auto_diag => 1, allow_loose_quotes => 1, escape_char => undef});
        print "Loading CSV data for file: $_\n";
        open my $fh, "<:encoding(utf8)", $_ or die $_ . ": $!";
        $columns = $csv->getline($fh);
        s/ ^\s+ | \s+$ //gx for @$columns;
        $csv->column_names($columns);
        while (my $href = $csv->getline_hr($fh)) {
            for (values %$href) {
                s/ ^\s+ | \s+$ //gx if ($_);
            }
            push(@rows, $href);
        }
    }    
    print "WARNING: File is empty or containing only one line\n\n" unless (@rows);
    return \@rows;
}

# ========================================================================================== #

sub WriteCSV {
    my $array_of_hashes = shift;
    my $file = shift;

    open( FH, ">$file" ) || die "Couldn't open $file $!";
    binmode(FH, ":utf8");

    local $" = ",";
    print FH "@{$cols_order}\n";

    foreach my $row (@{$array_of_hashes}){
        foreach my $col (@{$cols_order}){
            if($row->{$col}){
                print FH '"' . $row->{$col} . '",';
            }
            else{
                print FH '"",';
            }
        }
        print FH "\n";
    }
    close FH;

    print "Unique rows stored in file $file\n";
}
