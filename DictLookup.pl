#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
	if($ARGV[0] =~ /^-f=/) {
		@temparray = split(/=/, $ARGV[0]);
		$fileID = @temparray[1];
	}
}

system("cat outputs/res-" . $fileID . "-1-1untagged.txt | perl ../morphind/MorphInd.pl -disambiguate=0 >outputs/res-" . $fileID . "-morphind.txt");
system("cat outputs/res-" . $fileID . "-1-1untaggedParticle.txt | perl ../morphind/MorphInd.pl -disambiguate=0 >outputs/res-" . $fileID . "-morphindParticle.txt");
open(IN,"outputs/res-" . $fileID . "-1-1tag.txt");
open(UNTAGGED, "outputs/res-" . $fileID . "-1-1untagged.txt");
open(UNTAGGEDPARCTICLE, "outputs/res-" . $fileID . "-1-1untaggedParticle.txt");
open(MORPHIND, "outputs/res-" . $fileID . "-morphind.txt");
open(MORPHINDPARTICLE, "outputs/res-" . $fileID . "-morphindParticle.txt");
open(PREMORPHANALYSIS, ">outputs/res-" . $fileID . "-preMorphAnalysis.txt");
open(PREMORPHANALYSISPARTICLE, ">outputs/res-" . $fileID . "-preMorphAnalysisParticle.txt");
open(OUT, ">outputs/res-" . $fileID . "-dictTag.txt");

use Storable;

%untaggedLines = %{retrieve('outputs/res-' . $fileID . '-untaggedWords.ptg')};
%untaggedParticleLines = %{retrieve('outputs/res-' . $fileID . '-untaggedWordsNYA.ptg')};

# Array berisi index kata yang belum diberi tag
@untaggedWord = sort { $a <=> $b } keys %untaggedLines;
@untaggedParticleWord = sort { $a <=> $b } keys %untaggedParticleLines;
@morphind;
@morphindParticle;
$line = 1;
$i = 0;
$j = 0;

while($temp = <MORPHIND>) {
	chomp $temp;
	$temp2 = <UNTAGGED>;
	chomp $temp2;
	print PREMORPHANALYSIS $temp2 . "\t" . $temp . "\n";
}

while($temp = <MORPHINDPARTICLE>) {
	chomp $temp;
	$temp2 = <UNTAGGEDPARCTICLE>;
	chomp $temp2;
	print PREMORPHANALYSISPARTICLE $temp2 . "\t" . $temp . "\n";
}

system("java -classpath binary MorphAnalysis -f=outputs/res-" . $fileID . "-preMorphAnalysis.txt -o=outputs/res-" . $fileID . "-morphAnalysis.txt");
open(MORPHANALYSIS, "outputs/res-" . $fileID . "-morphAnalysis.txt");

system("java -classpath binary MorphAnalysis -f=outputs/res-" . $fileID . "-preMorphAnalysisParticle.txt -o=outputs/res-" . $fileID . "-morphAnalysisParticle.txt");
open(MORPHANALYSISPARTICLE, "outputs/res-" . $fileID . "-morphAnalysisParticle.txt");

# Membaca hasil tagging dari MorphInd untuk kata-kata yang belum diberi tag
while(my $temp = <MORPHANALYSIS>) {
	chomp $temp;
	push(@morphind, $temp);
}
while(my $temp = <MORPHANALYSISPARTICLE>) {
	chomp $temp;
	push(@morphindParticle, $temp);
}

# Membaca data kata-kata yang akan diberi tag
while(my $temp = <IN>) {
	chomp $temp;
	
	# Jika bertemu dengan indeks yang belum diberi tag,
	# lakukan tagging sesuai dengan kamus KBBI/MorphInd
	if($line == $untaggedWord[$i]) {
		#do tagging from dictionary
		if($line == $untaggedParticleWord[$j]) {
			my @tag = split(/\t/, $morphindParticle[$j]);
			if($tag[1]) {
				print OUT $morphindParticle[$j] . "\n";
				if($untaggedParticleLines{$line} =~ /nya/) {
					print OUT $untaggedParticleLines{$line} . "\t" . "PRP" . "\n";
				}
				elsif($untaggedParticleLines{$line} =~ /kah|lah|pun/) {
					print OUT $untaggedParticleLines{$line} . "\t" . "RP" . "\n";
				}
			}
			else {
				print OUT $morphind[$i] . "\n";	
			}

			if($j < scalar @untaggedParticleWord) {
				
				$j++;
			}
		}
		else {
			print OUT $morphind[$i] . "\n";
		}

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