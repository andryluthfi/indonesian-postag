#!/bin/bash

MODE=$1
INPUT=$2
VERBOSE=$3
if [ "$MODE" == "-file" ]; then
    if [ "$VERBOSE" == "-verbose" ]; then
    	# echo "mode file $INPUT verbose"
    	perl NER.pl -f=$INPUT -verbose
    else
    	# echo "mode file not verbose"
    	perl NER.pl -f=$INPUT
    fi
    cat outputs/res-$INPUT-resolved.txt
fi
if [ "$MODE" == "-raw" ]; then
    rm outputs/res-0000000-*
    echo $INPUT > outputs/res-0000000-input.txt
    if [ "$VERBOSE" == "-verbose" ]; then
    	# echo "mode raw $INPUT verbose"
    	perl NER.pl -f=0000000 -verbose
    	echo "Input : $INPUT"
    	echo "Output:"
    else
    	# echo "mode raw not verbose"
    	perl NER.pl -f=0000000
    fi
    cat outputs/res-0000000-resolved.txt
fi