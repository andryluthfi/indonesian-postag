#!/usr/local/bin/perl

$fileID = "";

if(scalar @ARGV > 0) {
    if($ARGV[0] =~ /^-f=/) {
        @temparray = split(/=/, $ARGV[0]);
        $fileID = @temparray[1];
    }
}

open(IN, "outputs/res-" . $fileID . "-dictTag.txt");
open(AMBIGOUS, ">outputs/res-" . $fileID . "-ambigous.txt");

use Storable;

$isPush = 0;
$line = 1;
@ambigousWord = ();
@sentence;


# Membaca data kalimat-kalimat yang akan diberi tag
while($temp = <IN>) {
    chomp $temp;

    # Menemui akhir kalimat
    if($temp eq "") {
        PUSH:
        for($i = 0; $i < scalar @sentence;$i++) {
            @temparray = split(/\t/, $sentence[$i]); # Memecah antara kata dan tag dengan delimiter tertentu (\t)

            # Case 1: Sudah ada tag
            if(scalar @temparray > 1) {
                $temp2 = @temparray[1];
                @temparray2 = split(/,/, $temp2); # Memecah tag dengan delimiter tertentu (,)

                # Cek jika memiliki lebih dari satu kemungkinan tag
                if(scalar @temparray2 > 1){
                    # Jika ambigu maka catat ke daftar kata-kata ambigu (beserta konteksnya)
                    $ambigousIndex .= ($i+1) . ",";
                    push(@ambigousWord, $line);
                }
            }
			
            $line++;
        }
		$ambigousIndex =~ s/\,$//;
		print AMBIGOUS $ambigousIndex . "\n";
		for($j = 0; $j < scalar @sentence;$j++) {
			@temparray3 = split(/\t/, $sentence[$j]);
			print AMBIGOUS $temparray3[0] . "\t" . $temparray3[1] . "\n";
		}
		print AMBIGOUS "\n";
		$ambigousIndex = "";
        @sentence = ();
        $line++;
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

store (\@ambigousWord, 'outputs/res-' . $fileID . '-ambigousWord.ptg');

print "\n[Rule-BasedTagging.pl] Ambigous words collected...\n";
system("java -classpath binary ParseRule --inputname=outputs/res-" . $fileID . "-ambigous.txt --trace=true --outputname=outputs/res-" . $fileID . "-parserule.txt");
# Melanjutkan ke proses unknown/fw resolve
if($fileID eq "") {
    system("perl Resolver.pl");
}
else {
    system("perl Resolver.pl -f=" . $fileID);
}