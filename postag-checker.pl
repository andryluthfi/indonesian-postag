#!/usr/local/bin/perl

$fileID = "0001";
#open(IN,"wn-msa-all.tab") or die "can't open input file";
open(IN,"test.tab") or die "can't open input file";
open(INPOS,"outputs/res-" . $fileID . "-input.txt") or die "can't open postag input file";

while($temp = <IN>){
	@temparray = split(/\t/, $temp);
	$synset = $temparray[0];
	@temparray2 = split(/\-/, $synset);

	$synID = $temparray2[0];
	$synPos = $temparray2[1];
	$synDef = $temparray[3];

	print INPOS $synDef . "\n";
}

system("perl NER -f=" . $fileID);


