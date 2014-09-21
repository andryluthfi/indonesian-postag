#!/bin/bash

INPUT="Andry sedang makan nasi di rumah sakit"
rm outputs/res-0000000-*
echo $INPUT > outputs/res-0000000-input.txt
perl NER.pl -f=0000000
clear
echo "Input: " $INPUT
echo "Output: "
cat outputs/res-0000000-resolved.txt
