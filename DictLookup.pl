#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
	if($ARGV[0] =~ /^-f=/) {
		@temparray = split(/=/, $ARGV[0]);
		$fileID = @temparray[1];
	}
}

system("cat outputs/res-" . $fileID . "-1-1untagged.txt | perl morphind/MorphInd.pl -disambiguate=0 >outputs/res-" . $fileID . "-morphind.txt");
open(IN,"outputs/res-" . $fileID . "-1-1tag.txt");
open(UNTAGGED, "outputs/res-" . $fileID . "-1-1untagged.txt");
open(MORPHIND, "outputs/res-" . $fileID . "-morphind.txt");
open(PREMORPHANALYSIS, ">outputs/res-" . $fileID . "-preMorphAnalysis.txt");
open(OUT, ">outputs/res-" . $fileID . "-dictTag.txt");

use Storable;

%untaggedLines = %{retrieve('outputs/res-' . $fileID . '-untaggedWords.ptg')};

# Array berisi index kata yang belum diberi tag
@untaggedWord = sort { $a <=> $b } keys %untaggedLines;
@morphind;
$line = 1;
$i = 0;

while($temp = <MORPHIND>) {
	chomp $temp;
	$temp2 = <UNTAGGED>;
	chomp $temp2;
	print PREMORPHANALYSIS $temp2 . "\t" . $temp . "\n";
}

system("java MorphAnalysis -f=outputs/res-" . $fileID . "-preMorphAnalysis.txt -o=outputs/res-" . $fileID . "-morphAnalysis.txt");
open(MORPHANALYSIS, "outputs/res-" . $fileID . "-morphAnalysis.txt");

# Membaca hasil tagging dari MorphInd untuk kata-kata yang belum diberi tag
while($temp = <MORPHANALYSIS>) {
	chomp $temp;
	push(@morphind, $temp);
}

# Membaca data kata-kata yang akan diberi tag
while($temp = <IN>) {
	chomp $temp;
	
	# Jika bertemu dengan indeks yang belum diberi tag,
	# lakukan tagging sesuai dengan kamus KBBI/MorphInd
	if($line == $untaggedWord[$i]) {
		#do tagging from dictionary
		print OUT $morphind[$i] . "\n";
		
		if($i < scalar @untaggedWord) {
			$i++;
		}
	}
	else {
		print OUT $temp . "\n";
	}
	$line++;
}

print "\n[DictLookup.pl] Tagged based on KBBI/MorphInd...\n";
# Melanjutkan ke proses rule-based tagging
if($fileID eq "") {
	system("perl Rule-BasedTagging.pl");
}
else {
	system("perl Rule-BasedTagging.pl -f=" . $fileID);
}