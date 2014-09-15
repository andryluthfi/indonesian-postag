#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
	if($ARGV[0] =~ /^-f=/) {
		@temparray = split(/=/, $ARGV[0]);
		$fileID = @temparray[1];
	}
}

open(FIXED,"resources/1-1 tag dict v2.txt");
open(FIXEDREGEX,"resources/1-1 tag regex.txt");
open(IN,"outputs/res-" . $fileID . "-NER.txt");
open(OUT, ">outputs/res-" . $fileID . "-1-1tag.txt");
open(UNTAGGED, ">outputs/res-" . $fileID . "-1-1untagged.txt");

use Storable;

%fixedtag = ();
%fixedtagRegex = ();
@regex = ();
%untaggedWords = ();
$line = 1;

# Membaca kamus yang berisi kata-kata dengan kemungkinan postag yang telah diketahui
while($temp = <FIXED>) {
	chomp $temp;
	next if($temp eq "" || $temp =~ /^\#/);
	
	@temparray = split(/\t/, $temp);
	$fixedtag{lc($temparray[0])} = $temparray[1];
}
while($temp = <FIXEDREGEX>) {
	chomp $temp;
	next if($temp eq "" || $temp =~ /^\#/);
	
	@temparray = split(/\t/, $temp);
	$fixedtagRegex{$temparray[0]} = $temparray[1];
}
@regex = keys (%fixedtagRegex);

# Membaca data kata-kata yang akan diberi tag
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
			# Lewati saja (tetap print kata dan tag yang sudah ada)
			print OUT $temp . "\n";
		}
		
		# Case 3: Belum ada tag
		else {
			# Jika kata tersebut ada di dalam kamus maka berikan tag yang sesuai
			if(exists $fixedtag{lc($temparray[0])}) {
				# do tagging
				print OUT $temparray[0] . "\t" . $fixedtag{lc($temparray[0])} . "\n";
			}
			# Jika tidak ada di dalam kamus 1-1 tag dict maka coba cek regex
			# Jika tidak ada regex yang cocok maka lewati saja(tetap print kata yang ada)
			else {
				$flagRegex = 0;
				for($i=0; $i<scalar @regex; $i++) {
					if($temparray[0] =~ /$regex[$i]/i) {
						print OUT $temparray[0] . "\t" . $fixedtagRegex{$regex[$i]} . "\n";
						$flagRegex++;
						last;
					}
				}
				if($flagRegex == 0) {				
					print OUT $temparray[0] . "\n";
					print UNTAGGED $temparray[0] . "\n";
					$untaggedWords{$line} = $temparray[0];
				}
			}
		}
	}
	
	$line++;
}

store (\%untaggedWords, 'outputs/res-' . $fileID . '-untaggedWords.ptg');

print "\n[1-1Tagging.pl] Tagged based on 1-1 tag dictionary...\n";
# Melanjutkan ke proses Dictionary Look-up
# (Mengirim file res-1-1untagged.txt ke Dictionary Lookup app)
if($fileID eq "") {
	system("perl DictLookup.pl");
}
else {
	system("perl DictLookup.pl -f=" . $fileID);
}