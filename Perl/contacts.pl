#! /usr/bin/perl

# This script is used to convert list of contacts from 
# normal text file in specified format to contact(.vcf) file.

use strict;
use warnings;
use Data::Dumper;
use Text::vCard::Addressbook;

open F , "<contacts.txt";
my @contacts_data;
my $contacts;
@contacts_data = map { chomp $_; $_; } <F>;
close F;
#$"="\n";
#print "@contacts_data";
my $pos;
my $loc;
my $count;
my $avoid = {
	LUID => 1,
};

open OF , ">contacts.vcf";
print OF "BEGIN:VCARD\n";
print OF "VERSION:3.0\n";
#my $address_book = Text::vCard::Addressbook->new();
my $vcard;
foreach my $line (@contacts_data){
	if($line =~ m/Location = (.+)/i){
		$pos = $1;
		#$vcard = $address_book->add_vcard;
		print OF "END:VCARD\n";
		print OF "BEGIN:VCARD\n";
		print OF "VERSION:3.0\n";
	}
	elsif($line =~ m/^([A-Za-z]+)$/){
		$loc = $1;
	}
	elsif($line =~ m/(.+)Name = (.+)/){
		$contacts->{$pos}->{Name}->{$1} = $2;
		#$vcard->fullname($2) if($1 eq 'Formal');
		print OF "FN:$2\n" if($1 eq 'Formal');
	}
	elsif($line =~ m/Number(.+) = (.+)/){
		$count = $count + 1;
		$loc = "WORK" if(not $loc);
		$contacts->{$pos}->{'Number'}->{$loc}->{$1} = $2;
		#$vcard->EMAIL($2) if($1 eq 'Mobile');
		print OF "TEL;TYPE=VOICE,".uc($loc).":$2\n";
	}
	elsif($line =~ m/Email = (.+)/){
		$contacts->{$pos}->{'Email'}->{$loc} = "$1";
                #$vcard->EMAIL("$1");
		print OF "EMAIL;TYPE=WORK:$1\n";
	}
	elsif($line =~ m/(.+) = (.+)/){
		$contacts->{$pos}->{$loc}->{$1} = $2 if(not defined $avoid->{$1});
	#	print OF "\n";
	}
}

=head
open OF , ">contacts.vcf";

print OF $address_book->export;

close OF;
=cut

#open OF , ">contacts.hash";

#print OF Dumper($contacts);

close OF;


#print Dumper(sort(keys($contacts)));
