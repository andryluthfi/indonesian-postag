#!/usr/local/bin/perl

open(IN, "Ara-1.txt");
open(OUT, ">Ara-1-out.txt");

$teks = "";

while($temp = <IN>) {
	$teks .= $temp;
}

$teks =~ s/\n/ /g;
$teks =~ s/  /\n/g;

print OUT $teks;