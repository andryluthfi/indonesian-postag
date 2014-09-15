#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
	if($ARGV[0] =~ /^-f=/) {
		@temparray = split(/=/, $ARGV[0]);
		$fileID = @temparray[1];
	}
}

open(IN,"outputs/res-" . $fileID . "-dictTag.txt");
open(PARSERULE, "outputs/res-" . $fileID . "-parserule.txt");
open(OUT, ">outputs/res-" . $fileID . "-resolved.txt");

use Storable;

@ambigousWord = @{retrieve('outputs/res-' . $fileID . '-ambigousWord.ptg')};
@parser = ();
$line = 1;
$iterate = 0;

# Membaca hasil tagging dari MorphInd untuk kata-kata yang belum diberi tag
while($temp = <PARSERULE>) {
	chomp $temp;
	if($temp ne "") {
		push(@parser, $temp);
	}
}

# Membaca data kalimat-kalimat yang akan diberi tag
while($temp = <IN>) {
	chomp $temp;
	
	# Case 1: New line
	if($temp eq "") {
		# print new line
		print OUT "\n";
	}
	
	else {
		@temparray = split(/\t/, $temp); # Memecah antara kata dan tag dengan delimiter tertentu (\t)
		
		# Case 2: Sudah ada tag
		if(scalar @temparray > 1) {
			# Jika merupakan kata yang sebelumnya ambigu, maka gunakan hasil dari parse rule
			if($line == $ambigousWord[$i]) {
				#do tagging from rule disambiguation
				print OUT $parser[$i] . "\n";
				
				if($i < scalar @ambigousWord) {
					$i++;
				}
			}
			else {
				print OUT $temp . "\n";
			}
		}
		
		# Case 3: Belum ada tag
		else {
			# Jika diawali huruf besar asumsikan Proper Noun (NNP)
			if ($temparray[0] =~ /^[A-Z]/) {
				print OUT $temparray[0] . "\t" . "NNP" . "\n";
			}
			# do tagging for unknown (X)
			else {
				print OUT $temparray[0] . "\t" . "X" . "\n";
			}
		}
	}
	
	$line++;
}

# Proses resolve selesai (hasil final tagging)
print "\n[Resolver.pl] Resolved...\n";
