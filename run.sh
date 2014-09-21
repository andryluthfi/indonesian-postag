#!/bin/bash
# this file is only for the webservice calling purpose only

cd /var/www/postag/bin/tagger
perl /var/www/postag/bin/tagger/NER.pl -f=$1