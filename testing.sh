#!/bin/bash

INPUT="Fam sedang memasak nasi untuk ibu."
rm outputs/res-0000000-*
echo $INPUT > outputs/res-0000000-input.txt
perl NER.pl -f=0000000
clear
echo "Input: " $INPUT
echo "Output: "
cat outputs/res-0000000-resolved.txt
