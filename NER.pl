#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
	if($ARGV[0] =~ /^-f=/) {
		@temparray = split(/=/, $ARGV[0]);
		$fileID = @temparray[1];
	}
}

system("java -classpath binary PrefixTree outputs/res-" . $fileID . "-input.txt > outputs/res-" . $fileID . "-PrefixTree.txt");
open(IN, "outputs/res-" . $fileID . "-PrefixTree.txt") or die "cannot open < outputs/res-" . $fileID . "-PrefixTree: $!";
print "\n[NER.pl] Document tokenized...\n";
open(OUT, ">outputs/res-" . $fileID . "-NER.txt");

$isPush = 0;
@sentence;


# Membaca data kalimat-kalimat yang akan diberi tag
while($temp = <IN>) {
    chomp $temp;

    # Menemui akhir kalimat
    if($temp eq "") {
        PUSH:
        for($i = 0; $i < scalar @sentence;$i++) {
            @temparray = split(/\t/, $sentence[$i]); # Memecah antara kata dan tag dengan delimiter tertentu (\t)

            # Case 1: Sudah ada tag dari MWE -> mapping ke tagset yang kita miliki
            if(scalar @temparray > 1) {
            	if($temparray[1] eq "noun"){
            		$mappingTag = "\tNN";
            	}
            	elsif($temparray[1] eq "verb"){
            		$mappingTag = "\tVB";
            	}
            	elsif($temparray[1] eq "adjective"){
            		$mappingTag = "\tJJ";
            	}
            	elsif($temparray[1] eq "adverb"){
            		$mappingTag = "\tRB";
            	}
            	elsif($temparray[1] eq "pronoun"){
            		$mappingTag = "\tPR,PRP";
            	}
            	elsif($temparray[1] eq "numeric"){
            		$mappingTag = "\tCD,OD";
            	}
            	elsif($temparray[1] eq "other"){
            		$mappingTag = "";
            	}
            	else{
            		$mappingTag = "";
            	}
				print OUT $temparray[0] . $mappingTag . "\n";
            }
			
			else {
				# Jika diawali huruf besar dan bukan awal kalimat maka asumsikan Proper Noun
				if($sentence[$i] =~ /^[A-Z]/) {
					if($i == 1 && $sentence[0] =~ /^[A-Za-z0-9]/) {
						print OUT $sentence[$i] . "\tNNP\n";
					}
					elsif($i > 1) {
						print OUT $sentence[$i] . "\tNNP\n";
					}
					else {
						print OUT $sentence[$i] . "\n";
					}
				}
				else {
					print OUT $sentence[$i] . "\n";
				}
			}
        }
		print OUT "\n";
        @sentence = ();
    }

    # Menemui token
    else {
        push(@sentence, $temp);
    }
}
if($isPush == 0) {
    $isPush++;
    goto PUSH;
}

print "\n[NER.pl] Name Entity recognized...\n";
# Melanjutkan ke proses 1-1 Tagging menggunakan kamus
if($fileID eq "") {
	system("perl 1-1Tagging.pl");
}
else {
	system("perl 1-1Tagging.pl -f=" . $fileID);
}
