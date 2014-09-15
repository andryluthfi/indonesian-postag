#!/usr/local/bin/perl

open(INPUT,"input.txt");
open(OUT, ">res-token.txt");

$text;

# Membaca input dari file
while($temp = <INPUT>) {
	chomp $temp;
	$text .= " " . $temp;
}
$text =~ s/^\s+|\s$//;
# print $text;

# Melakukan tokenisasi
@token = tokenize($text);
foreach $t (@token) {
	print OUT $t . "\n";
	if($t =~ /\.$|\?$|\!$/) {
		print OUT "\n";
	}
}

sub tokenize {
	my $string = shift;
	
	$string =~ s/(?<=[A-Za-z])(?=\.|\,|\!|\?|\'|\"|\$)/ /g;
	$string =~ s/(?<=\.|\,|\!|\?|\'|\"|\$)(?=[A-Za-z])/ /g;
	#print $string;
	my @words = split(/\s/, $string);
}

sub token {
	my $msg = shift;

	my $ntd = qr/(?<=\D)[,.]/;  
	my $dtn = qr/[,.](?=\D|$)/; 
	my $nv = qr/[^A-Za-z0-9\'\$!-.,]+/; 
 
	my %words;
	my @words = grep { !/^$/ and !$words{lc($_)}++} 
               split /$ntd|$dtn|$nv/,$msg;    
	return @words;
}

print "[Tokenizer.pl] Document tokenized ...\n";