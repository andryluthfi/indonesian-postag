#!/bin/bash

INPUT="Fam sedang membaca apakah skripsi miliknya yang tebalnya 100 halaman itu berkilah tentang sesuatu di kantor"
rm outputs/res-0000000-*
echo $INPUT > outputs/res-0000000-input.txt
perl NER.pl -f=0000000
clear
echo "Input: " $INPUT
echo "Output: "
cat outputs/res-0000000-resolved.txt
