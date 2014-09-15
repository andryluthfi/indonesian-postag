#!/usr/bin/perl

## ==================================================================
## Indonesian Morphological Tool (MorphInd)
## Version 1.4
## Author        : Septina Dian Larasati
##                 (septina.larasati@gmail.com)
##                 (larasati@ufal.mff.cuni.cz)
## Last Modified : May 2013
## ==================================================================
## Copyright (c) 2013 Septina Dian Larasati.  All rights reserved.


## Indonesian Morphological Tool (MorphInd)
##
## Usage:
## bash$ cat INPUTFILE | perl MorphInd.pl  > OUTPUTFILE
## bash$ echo "mengirim" | perl MorphInd.pl  > OUTPUTFILE
## bash$ cat INPUTFILE | perl MorphInd.pl [-cache-file CACHEFILE -bin-file BINARYFILE -disambiguate (0/1)] > OUTPUTFILE
##
## Example:
## bash$ cat sample.txt | perl MorphInd.pl > sample.out
## bash$ cat sample.txt | perl MorphInd.pl -cache-file cache-files/default.cache \
##      -bin-file bin/morphind.bin -disambiguate 1 > sample.out

## Input example  : "mengirim"
## Output example : "^meN+kirim<v>_VSA$" 


use warnings;
use strict;
use Getopt::Long "GetOptions";
use FindBin qw($Bin);
use utf8;

binmode(STDIN,  ":utf8");
binmode(STDOUT, ":utf8");


## Getting the input parameters
my ( $INPUT_FILE, $CACHE_FILE, $BIN_FILE, $_OVERRIDE, $_DISAMBIGUATE, $TAG_FILE, $QUERY_TOOL, $COMPOUND_FILE, $HELPWORD );
$CACHE_FILE = "$Bin/cache-files/default.cache";
$BIN_FILE   = "$Bin/bin-files/morphind.bin";
$TAG_FILE   = "$Bin/bin-files/tag.lm.bin";
$QUERY_TOOL = "$Bin/bin-files/query";
$COMPOUND_FILE = "$Bin/cache-files/default.compound";
$HELPWORD = "majalah";
$_OVERRIDE = 0;
$_DISAMBIGUATE = 1;



if ( !&GetOptions( 'cache-file=s' => \$CACHE_FILE, # allow to override default cache file from STDIN
                   'bin-file=s' => \$BIN_FILE,     # allow to override default bin   file from STDIN
#                   'override-cache=i' => \$_OVERRIDE,
                   'disambiguate=i' => \$_DISAMBIGUATE ) ) {
    &help_message();
}

&GetOptions( 'cache-file=s' => \$CACHE_FILE, # allow to override default cache file from STDIN
             'bin-file=s' => \$BIN_FILE,     # allow to override default bin   file from STDIN
#             'override-cache=i' => \$_OVERRIDE,
             'disambiguate=i' => \$_DISAMBIGUATE );


## Collecting the cache data
my %CACHE;
my %INITCACHE;
my %OBVIOUS;
if ( $CACHE_FILE eq "-" ) { %CACHE = (); }
else {
    open( CACHE, $CACHE_FILE );
    binmode(CACHE, ":utf8");
    while ( <CACHE> ) {
        chomp();
        my ( $form, $analysis ) = split( /\t/, $_ );
        $CACHE{ $form } = $analysis;
        $INITCACHE{ $form } = $analysis;
    }
    close( CACHE );
}

my %COMPOUND = ();
my $MAX_COMPOUND = 0;
if ( $COMPOUND_FILE eq "-" ) { %CACHE = (); }
else {
    open( COMPOUND, $COMPOUND_FILE );
    binmode(COMPOUND, ":utf8");
    while ( <COMPOUND> ) {
        chomp();
        my ( $form, $analysis ) = split( /\t/, $_ );
        my @ws = split( / +/, $form );
        $COMPOUND{ scalar( @ws ) }{ $form } = $analysis;
        if ( $MAX_COMPOUND < scalar( @ws ) ) {
            $MAX_COMPOUND = scalar( @ws );
        }
    }
    close( COMPOUND );
}



my $INPUT_CONTENT = "";
my ( %UNANALYZED, %SPECIAL );
my $LINECHECK = "";
my %SEEN = ();
my $sent = 0;
print STDERR "Collecting Vocabulary:\n";
while ( my $line = <STDIN> ) {
    if ( ($sent+1) % 1000 eq 0 ) {
        my $c = ( ($sent+1) / 1000 ) % 10; 
        print STDERR "".$c;
    }
    $sent++;

    $line = lc( $line );

    $line =~ s/\-ku /ku /g;
    $line =~ s/\-ku$/ku/g;
    $line =~ s/\-mu /mu /g;
    $line =~ s/\-mu$/mu/g;
    $line =~ s/\-nya /nya /g;
    $line =~ s/\-nya$/nya/g;
    $line =~ s/ ke\-/ ke/g;
    $line =~ s/^ke\-/ke/g;
    $line =~ s/\-lah /lah /g;
    $line =~ s/\-lah$/lah/g;
    $line =~ s/(\d+)\-an /$1an /g;
    $line =~ s/(\d+)\-an$/$1an/g;
    $line =~ s/\-kan /kan /g;
    $line =~ s/\-kan$/kan/g;

    $line =~ s/ antar\-/ antar/g;
    $line =~ s/^antar\-/antar/g;
    $line =~ s/ non\-/ non/g;
    $line =~ s/^non\-/non/g;
    $line =~ s/^anti\-/anti/g;
    $line =~ s/ anti\-/ anti/g;
    $line =~ s/ ketidak\-/ ketidak/g;
    $line =~ s/^ketidak\-/ketidak/g;
    $line =~ s/ di\-/ di/g;
    $line =~ s/^di\-/di/g;
    $line =~ s/ me(m|ng|ny)\-/ me$1/g;
    $line =~ s/^me(m|ng|ny)\-/me$1/g;

    $line =~ s/ (al|an|el)\-/ $1EXPLINE/g;
    $line =~ s/^(al|an|el)\-/$1EXPLINE/g;

    my $lined = $line;
    $INPUT_CONTENT .= &segmentthis( $line )."\n";
    $line =~ s/([^\-\d\s]+)\-\1/\nTAKETHISA$1\-$1TAKETHISB\n/g;
    $line =~ s/\nTAKETHISA\s*([^\n\-]+)\s*\-\s*\1\s*TAKETHISB\n/ $1\-$1 /g;
    $line =~ s/ +/ /g;
    $line =~ s/^ //g;
    $line =~ s/ $//g;

    
    $lined =~ s/\-/ /g;
    $line .= " ".$lined;
    $line =~ s/\n/ /g;
    $line =~ s/ +/ /g;
    $line =~ s/^ //g;
    $line =~ s/ $//g;

    while ( $line =~ s/([\S]+)\s*// ) {
        my $token = $1;
        
        if ( defined( $SEEN{ $token } ) ) { next; }
        $SEEN{ $token } = 1;
        
        my ( $head, $main, $tail ) = &strip( $token );

        if ( !defined( $UNANALYZED{ $head.$HELPWORD.$tail } ) ) {
            $UNANALYZED{ $head.$HELPWORD.$tail } = 0;
        }
        $UNANALYZED{ $head.$HELPWORD.$tail }++;
        
        if ( $token =~ m/([m|p]e)(.){0,2}([^\-]+)\-(.)\3(.*)/ ) {
#        if ( 0 ) {
            my $word = $4.$3."\-".$4.$3;
            my $help = $1.$HELPWORD .$5;
            if ( !defined( $SPECIAL{ $word } ) ) {
                $UNANALYZED{ $word } = 0;
                $SPECIAL{ $word } = 0;
                $line = $line." ".$word;
                $UNANALYZED{ $help } = 0;
                $SPECIAL{ $help } = 0;
                $line = $line." ".$help;
            }
            $UNANALYZED{ $word }++;
            $SPECIAL{ $word }++;
            $UNANALYZED{ $help }++;
            $SPECIAL{ $help }++;

        }

        $token = mark_special_char( $token );
        my $analysis = "";
        my $tmp = $token;
        $tmp =~ s/DOT/D/g;

        # Punctuations    
        if ( $token =~ m/^\W+$/ | $token =~ m/^[A-Z]+$/ | $token =~ m/^\_+$/ ) {
            $analysis = "\^".$token."\<z\>\_Z--\$";
            $token = unmark_special_char( $token );
            $analysis = unmark_special_char( $analysis );
            $CACHE{ $token } = $analysis;
        }
        # Digits
        elsif ( $tmp =~ m/^(DASH|)([\d\,D]+)$/ ) {
            $analysis = $token;
            $analysis =~ s/DASH/\-/g;
            $analysis =~ s/DOT/\./g;
            $token = unmark_special_char( $token );
            $CACHE{ $token } = "\^".$analysis."\<c\>\_CC\-\$";
        }
        # Abbreviation updated: 10.10.2012
        elsif ( $token =~ m/[a-z0-9]DOT/ ) {
            $analysis = $token;
            $analysis =~ s/DASH/\-/g;
            $analysis =~ s/DOT/\./g;
            $token = unmark_special_char( $token );
            $CACHE{ $token } = "\^".$analysis."\<f\>\_F\-\-\$";
        }
        # straightforward cases: lowercased words only
        elsif ( $token =~ m/^[a-z]+$/ ) {
            $UNANALYZED{ $token }++;
        }
        elsif ( $token =~ m/^[a-z\-]+$/ ) {
            my $tmp3 = $token;
            $tmp3    =~ s/\-//g;
            $UNANALYZED{ $tmp3 }++;
        }
        # special cases: not lowercased words only
        else {
            $SPECIAL{ $token }++;
            $CACHE{ $token } = "\^".$token."\<x\>\_X--\$";  # default: unknown
            $token =~ s/([A-Z]+)/ $1 /g;
            $line = $line." ".$token;
            if ( $token =~ m/ DASH / ) {
                $token =~ s/ DASH //g;
                $line = $line." ".$token;
            }
        }
    }
}

my $uniquetmp = `echo \$\$`;
chomp( $uniquetmp );
open( TEMP, ">$Bin/cache-files/$uniquetmp.tmp" );
print TEMP "load $Bin/bin-files\/morphind.bin\n";
my @word = ( sort keys %UNANALYZED );
for ( my $i = 0; $i < scalar( @word ); $i++ ) {
    print TEMP "apply up ".$word[ $i ]."\necho \#SENTINEL\#\n";
}
close( TEMP );

my $analysis = `foma -q -f $Bin/cache-files/$uniquetmp.tmp`;
$analysis =~ s/\n/\//g;
$analysis =~ s/\/\#SENTINEL\#\/?/\n/g;

my @output = split( /\n+/, $analysis );
for ( my $i = 0; $i < scalar( @output ); $i++ ) {
    $analysis = $output[ $i ];
    if ( $analysis eq "\?\?\?" ) { $analysis = $word[ $i ]."\<x\>\_X\-\-"; }
    $analysis = "\^".$analysis."\$";
    $CACHE{ $word[ $i ] } = $analysis;
}

foreach my $original ( sort keys %INITCACHE ) {
    $CACHE{ $original } = $INITCACHE{ $original };
}

my $command = `rm $Bin/cache-files/$uniquetmp.tmp`;

foreach my $special ( sort keys %SPECIAL ) {
    my $analysis = "";
    my $tmp = $special;
    while ( $tmp =~ s/([^A-Z]+)([A-Z]*)// ) {
        $analysis .= $CACHE{ $1 }.$2;
    }
    
    if( $analysis =~ m/(.*)DASH\1/ and $analysis =~ m/\// and $analysis =~ m/\_([NVA])S.(\$|\/)/ ) {
#    if ( 0 ) { 
        my @collection = ();
        if ( $special =~ m/^([^D]+)DASH\1$/ and $analysis =~ m/\// and $analysis =~ m/^(.+)DASH\1$/) {
            my $coll = $analysis;
            $coll =~ s/^\^(.+)\$DASH\^\1\$$/$1/g;
            @collection = split( /\//, $coll );
            my $flag = 1;
            my @ress = ();
            for ( my $ff = 0; $ff < scalar( @collection ); $ff++ ) {
                $collection[ $ff ] =~ s/(\_[NVA])S(.)$/$1P$2/;
                if ( $collection[ $ff ] !~ m/\_...$/ ) {
                    $flag = 0;
                }
                if ( $collection[ $ff ] =~ m/^[a-z]+\<.\>\_[NVA]P.$/ or $collection[ $ff ] =~ m/^[a-z]+\<.\>\+an\_[N]P.$/ ) {
                    push( @ress, $collection[ $ff ] );
                }
            }
            if ( $flag == 1 and scalar( @ress ) > 0 ) {
                $analysis = "^".join( "\/", @ress )."\$";
                $OBVIOUS{ $special } = $analysis;
                my $normalize = $special;
                $normalize =~ s/DASH/\-/;
                $OBVIOUS{ $normalize } = $analysis;
                next;
            }
        }
        
        
        if ( $analysis !~ m/\// ) {
            if ( $analysis =~ m/([^\/\^\$]+)\_(N|V)S(.)(\$|\/)(.*)(\+[^\_]+\_PS.)\$/ ) {
                $analysis =~ m/([^\/\^\$]+)\_(N|V)S(.)(\$|\/)(.*)(\+[^\_]+\_PS.)\$/;
                $analysis = "^".$1."_$2P$3$6\$";
            }
    #        elsif ( $analysis =~ m/([^\/\^\$]+)\_(N|V)S(.)(\$|\/)([^\$]*)\$/ ) {
            elsif ( $analysis =~ m/([^\/\^\$]+)\_(N|V)S(.)(\$|\/)([^\$]*)\$/ and $special =~ m/([a-z]+)DASH\1/) {
                $analysis =~ m/([^\/\^\$]+)\_(N|V)S(.)(\$|\/)([^\$]*)\$/;
                $analysis = "^".$1."_$2P$3\$";
            }
            else {
            }
        }
        else {
#            delete ( $CACHE{ $special } );
#            my $normalize = $special;
#            $normalize =~ s/^([^D]+)DASH\1$/$1/;
#            if ( $special =~ m/^([^D]+)DASH\1$/ and defined( $CACHE{ $normalize } ) ) {
#                delete ( $CACHE{ $special } );
#                print STDERR "(2): ".$special."\n";
#            }
#            my $normalize = $special;
#            $normalize =~ s/DASH/\-/g;
#            $normalize = &smallsegment( $normalize );
#            if ( $normalize =~ m/SSS/ ) {
#                delete ( $CACHE{ $special } );
#                $normalize = $special;
#                $normalize =~ s/DASH/\-/g;
#                delete ( $CACHE{ $normalize } );
#            }

            next;
        }
    }
    if( $analysis =~ m/(.*)(.+)(_.)S(.)\$[A-Z]+\^(meN\+|di\+|)\2([^\_]*)(\_...)([^\$]*)\$/ ) {
        $analysis = $1.$5.$2.$6.$3."P".$4.$8."\$";
    }
#    if( $analysis =~ m/(.*)(.+)(_.)S(.\$)[A-Z]+\^(meN\+|di\+|)\2([^\_]*)(\_...)(\+[^\_]+\_PS.)\$/ ) {
#        $analysis = $1.$5.$2.$6.$3."P".$4.$8;
#    }
    ## for exceptions
    else {
        # processing digits
        if ( $special =~ m/(ke)(DASH|)(\d+)$/ or $analysis =~ m/\^ke[^\$]*\$DASH[^\<]*\<c\>/ ) {
           $analysis = $special;
           $analysis =~ s/ke(DASH|)/ke\+/g;
           $analysis = "\^".$analysis."\<c\>\_CO\-\$";
        }
        elsif ( $special =~ m/(ke)(DASH|)(\d+)nya$/ or $analysis =~ m/\^ke[^\$]*\$DASH\^\d+nya<f>_F--/ ) {
           $analysis = $special;
           $analysis =~ s/ke(DASH|)/ke\+/g;
           $analysis =~ s/(\d+)nya/$1/;
           $analysis = "\^".$analysis."\<c\>\_CO\-\+dia\<p\>\_PS3\$";
        }
        elsif( $analysis =~ m/([^\<]+)(\<c\>)(\_CC-)(\$)[A-Z]+\^\1\2\3\+dia\<p\>\_PS3\$/ ) {
            $analysis = "\^".$1."\+".$1.$2."\+nya".$3."\$";
            $analysis =~ s/\_CC\-/\_CD\-/;
        }
        elsif ( $special =~ m/(\d+)(DASH|)an/ ) {
           $analysis = $special;
           $analysis =~ s/(DASH|)an/\+an\_ASP\$/g;
           $analysis =~ s/(\d+)/\^$1\<c\>/g;
        }

        ## Processing arabic term as in "al-quran" or 'an-...'
        elsif ( $special =~ m/^(al|an|el)EXPLINE([a-z]*)(.*)/ ) {
            $analysis = "\^$1-$2\<f\>\_F--\$".$3;
        }

        # starting with a dash
        if ( $special =~ m/^([A-Z]+)/ ) {
            $analysis = $1.$analysis;
            $analysis =~ s/^([A-Z]+)\^/\^$1\<z\>\_Z--\+/;
            $analysis = &unmark_special_char( $analysis );
        }
        if ( $special =~ m/([A-Z]+)$/ ) {
            $analysis = $analysis.$1;
            $analysis =~ s/\$?([A-Z]+)$/\+$1\<z\>\_Z--\$/;
            $analysis = &unmark_special_char( $analysis );
        }
        if ( $special =~ m/DASHnya$/ ) {
            $analysis =~ s/DASH.*nya.*/\+dia\<p\>\_PS3\$/;
            $analysis =~ s/\<x\>\_X\-\-\$\+dia\<p\>\_PS3/\<f\>\_F\-\-\$\+dia\<p\>\_PS3/;
            $analysis =~ s/\$?\+dia\<p\>\_PS3/\+dia\<p\>\_PS3/;
        }
    }
    

    $special = &unmark_special_char( $special );
    $CACHE{ $special } = $analysis;
}


my %ENDING;
#$ENDING{ "-nya" } = "+dia<p>_PS3";
$ENDING{ "nya" } = "+dia<p>_PS3";
$ENDING{ "ku" } = "+aku<p>_PS1";
$ENDING{ "mu" } = "+kamu<p>_PS2";
$ENDING{ "kau" } = "+kamu<p>_PS2";
$ENDING{ "lah" } = "+lah<t>_T--";

foreach my $token ( keys %CACHE ) {

#     if ( $CACHE{ $token } =~ m/\_X--\$$/ and $token =~ m/^([a-z]*)(-nya|nya|ku|mu|kau)$/) {
     if ( $CACHE{ $token } =~ m/\_X--\$$/ and $token =~ m/^([a-z]*)(nya|ku|mu|kau|lah)$/) {
         my $main = $1;
         my $clit = $2;
         if ( defined( $CACHE{ $main } ) ) {
             my $analysis = $CACHE{ $main };
             $analysis =~ s/^\^//;
             $analysis =~ s/\$$//;
             $analysis = "\^".$analysis.$ENDING{ $clit }."\$";
             $CACHE{ $token } = $analysis;
         }
     }
     
    if ( $token =~ m/^[a-z\-]+$/ ) {
        my $tmp3 = $token;
        $tmp3 =~ s/\-//g;
        
#        print STDERR $token."::".$tmp3."\n";
    
#        if ( defined( $CACHE{ $tmp3 } ) and $CACHE{ $token } =~ m/\_X\-\-/ ) {
        if ( defined( $CACHE{ $tmp3 } ) and $CACHE{ $tmp3 } !~ m/\_X\-\-/ ) {
            $CACHE{ $token } = $CACHE{ $tmp3 };
        }
    }
    
    if ( $token =~ m/^([^\-\d]+)DASH\1$/ ) {
        my $tmp3 = $1;
        if ( defined( $CACHE{ $tmp3 } ) and $CACHE{ $tmp3 } =~ m/\_X\-\-/ ) {
            $CACHE{ $tmp3 } =~ s/\<x\>\_X\-\-/\<n\>\_NSD/;
        }
        
        $CACHE{ $token } = $CACHE{ $tmp3 };
        $CACHE{ $token } =~ s/\_([A-Z123])[A-Z123]([A-Z123])/\_$1P$2/;
        $tmp3 = $token;
        $tmp3 =~ s/DASH/\-/;
        $CACHE{ $tmp3 } = $CACHE{ $token };
    }
    



}

#Cleaning similar per+ and peN+  updated: 10.10.2012
#reduplicated F-- to NPD
foreach my $key ( keys %CACHE ) {
    my $normalize = $key;
    $normalize =~ s/DASH/\-/g;

    if ( $key =~ m/DASH/ and !defined( $INITCACHE{ $key } ) ) {
        if ( $normalize !~ m/^([^\-]+)\-\1$/ ) {
            delete( $CACHE{ $normalize } );
        }
    }
    elsif ( defined( $INITCACHE{ $key } ) ) {
        $CACHE{ $key } = $INITCACHE{ $key };
        next;
    }

    my @chunks = ();
    if ( $normalize =~ m/^([^\-]+)\-\1$/ and defined( $CACHE{ $normalize } ) and $CACHE{ $normalize } !~ m/DASH/ ) {
        @chunks = ( $normalize );
    }
    else {
        @chunks = split( /DASH|\-/, $key );
    }

    foreach my $token ( @chunks ) {
    
        if ( !defined( $CACHE{ $token } ) ) {
            my $result = &findagain2( "", $token, "" );
            $CACHE{ $token } = $result;
        }

        if ( $CACHE{ $token } =~ m/\^per\+r([^\/]+)\/peN\+r\1\$/) {
            my $analysis = $CACHE{ $token };
            $analysis =~ s/\^per\+r([^\/]+)\/peN\+r\1\$/\^peN\+r$1\$/g;
            $CACHE{ $token } = $analysis;
        }
            
        if ( $CACHE{ $token } =~ m/^(\^[^\$]+\<f\>\_F\-\-\$)DASH\1$/ ) {
            my $analysis = $CACHE{ $token };
            $analysis =~ s/^(\^[^\$]+\<f\>\_F\-\-\$)DASH\1$/$1/g;
            $analysis =~ s/\<f\>/\<n\>/g;
            $analysis =~ s/\_F\-\-/\_NSD/g;
            $CACHE{ $token } = $analysis;        
        }
         
        if ( $_DISAMBIGUATE ) {
            &ruleout( $token );
        }
    }
    
}





## Printing out result
$INPUT_CONTENT .= "\n";
$INPUT_CONTENT =~ s/^\s*//;
print STDERR "\nPrinting Result:\n";
%SEEN = ();

my %IN = ();
my @lines = split( /\n/, $INPUT_CONTENT );
for ( my $i = 0; $i < scalar( @lines ); $i++ ) {
    my @token  = split( /\s+/, $lines[ $i ] );
    
#    print STDERR $lines[ $i ]."\n";
    
    for ( my $ii = 0; $ii < scalar( @token ); $ii++ ) {
        my $original  = $token[ $ii ];
        my $normalize = $token[ $ii ];
        $normalize =~ s/OOO/\-/g;
        
        my $checkword = $token[ $ii ];
        $checkword =~ s/OOO/\-/g;
        $checkword =~ s/DASH/\-/g;
        $checkword =~ s/HYPHEN/\-/g;
        
        if ( defined( $SEEN{ $original } ) ) {
            $token[ $ii ] = $SEEN{ $original };
            next;
        }
        
        if ( defined( $INITCACHE{ $normalize } ) ) {
            $token[ $ii ] = $INITCACHE{ $normalize };
            $SEEN{ $original } = $token[ $ii ];
            next;
        }
        
        if ( defined( $OBVIOUS{ $checkword } ) ) {
            $token[ $ii ] = $OBVIOUS{ $checkword };
            $SEEN{ $original } = $token[ $ii ];
            next;
        }
        
        if ( $token[ $ii ] =~ m/^(\d+)\-(\d+)$/ ) {
            $token[ $ii ] = "\^".$1."\<c\>\_CC\-\+\-\<z\>\_Z\-\-\+".$2."\<c\>\_CC\-\$";
            $SEEN{ $original } = $token[ $ii ];
            next;
        }
        elsif ( $token[ $ii ] =~ m/^(\-+)$/ ) {
            $token[ $ii ] = "\^".$1."\<z\>\_Z\-\-\$";
            $SEEN{ $original } = $token[ $ii ];
            next;
        }
        elsif ( $token[ $ii ] !~ m/OOO/ and $token[ $ii ] !~ m/\-/ ) {
            my ( $head, $main, $tail ) = &strip( $normalize );
             
            if ( $head eq "" and $tail eq "" ) {
                $token[ $ii ] = $CACHE{ $normalize };
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            elsif ( defined( $INITCACHE{ $main } ) ) {
                if ( !defined( $CACHE{ $head.$HELPWORD.$tail } ) or $CACHE{ $head.$HELPWORD.$tail } =~ m/\_X\-\-/ ) {
                    my $result = &findagain( $head, $main, $tail );
                    $CACHE{ $head.$HELPWORD.$tail } = $result;
                }
                
                my $one = $CACHE{ $head.$HELPWORD.$tail };
                my $two = $INITCACHE{ $main };
                
                $one =~ s/^\^//;
                $one =~ s/\$$//;
                $two =~ s/^\^//;
                $two =~ s/\$$//;
                
                if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/ ) {
                    $one =~ s/$HELPWORD\<.\>\_.../$two/;
                }
                else {
                    $two =~ s/\_...//;
                    $one =~ s/$HELPWORD\<.\>/$two/;
                }
                $token[ $ii ] = "\^".$one."\$";
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            #just to be safe
            $token[ $ii ] = $CACHE{ $normalize };
            $SEEN{ $original } = $token[ $ii ];
            next;
        }
        
        elsif ( defined( $CACHE{ $normalize } ) ) {

            my ( $head, $main, $tail ) = &strip( $normalize );
            if ( $head eq "" and $tail eq "" ) {
                $token[ $ii ] = $CACHE{ $normalize };
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            elsif ( defined( $INITCACHE{ $main } ) ) {
                if ( !defined( $CACHE{ $head.$HELPWORD.$tail } ) or $CACHE{ $head.$HELPWORD.$tail } =~ m/\_X\-\-/ ) {
                    my $result = &findagain( $head, $main, $tail );
                    $CACHE{ $head.$HELPWORD.$tail } = $result;
                }

                
                my $one = $CACHE{ $head.$HELPWORD.$tail };
                my $two = $INITCACHE{ $main };
                
                $one =~ s/^\^//;
                $one =~ s/\$$//;
                $two =~ s/^\^//;
                $two =~ s/\$$//;
                if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/ ) {
                    $one =~ s/$HELPWORD\<.\>\_.../$two/;
                }
                else {
                    $two =~ s/\_...//;
                    $one =~ s/$HELPWORD\<.\>/$two/;
                }
                $token[ $ii ] = "\^".$one."\$";
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            #just to be safe
            $token[ $ii ] = $CACHE{ $normalize };
            $SEEN{ $original } = $token[ $ii ];
            next;

        }
        else { #"mendingin-dinginkan" and "makan-minum"
            my ( $head, $main, $tail ) = &strip( $normalize );
            
            if ( $head eq "" and $tail eq "" and defined( $CACHE{ $normalize } ) ) {
                $token[ $ii ] = $CACHE{ $normalize };
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            elsif ( defined( $INITCACHE{ $main } ) ) {
#                        print STDERR "(a): ".$normalize."||".$main."here\n";                
                if ( !defined( $CACHE{ $head.$HELPWORD.$tail } ) or $CACHE{ $head.$HELPWORD.$tail } =~ m/\_X\-\-/ ) {
                    my $result = &findagain( $head, $main, $tail );
                    $CACHE{ $head.$HELPWORD.$tail } = $result;
                }
                
                my $one = $CACHE{ $head.$HELPWORD.$tail };
                my $two = $INITCACHE{ $main };
                
                $one =~ s/^\^//;
                $one =~ s/\$$//;
                $two =~ s/^\^//;
                $two =~ s/\$$//;
                if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/  and $one =~ m/$HELPWORD\<.\>\+/) {
                    $two =~ s///;
                    $one =~ s/$HELPWORD\<.\>/$two/;
                }

                if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/ ) {
                    $one =~ s/$HELPWORD\<.\>\_.../$two/;
                }
                else {
                    $two =~ s/\_...//;
                    $one =~ s/$HELPWORD\<.\>/$two/;
                }
                $token[ $ii ] = "\^".$one."\$";
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
            else {
                my $analysis = "";
                my $mark = "";

                if ( $token[ $ii ] =~ s/^OOO// ) {
                    $mark = "-";
                }
#                print STDERR "(x ): ".$token[ $ii ]."\n";
#                $token[ $ii ] =~ s/\-/OOO/g;
#                print STDERR "(xx): ".&smallsegment( $token[ $ii ] )."\n\n";
                my @parts = split( m/OOO/, $token[ $ii ] );
                for ( my $jj = 0; $jj < scalar( @parts ); $jj++ ) {
                    if ( $parts[ $jj ] !~ m/\-/) {
                        if ( defined( $CACHE{ $parts[ $jj ] } ) ) {
                            my $add = $CACHE{ $parts[ $jj ] }."HYPHEN";
                            if ( $mark ne "" ) {
                                $add =~ s/^\^/\^\-/;
                                $mark = "";
                            }
                            $analysis .= $add;
                        }
                        else {
                            print STDERR "I: $i ".scalar(@token).":: ".join( " ", @token )."\n";
                        }
                    }
                    elsif( defined( $CACHE{ $parts[ $jj ] } ) ) {
                        my $add = $CACHE{ $parts[ $jj ] }."HYPHEN";
                        if ( $mark ne "" ) {
                            $add =~ s/^\^/\^\-/;
                            $mark = "";
                        }
                        $analysis .= $add;
                    }
                    else {
                        my @miniparts = split( /\-/, $parts[ $jj ] );
                        my $tmp = &smallsegment( $parts[ $jj ] );

                        $tmp = "A".$tmp."B";
                        my @tinymini = split( /SSS/, $tmp );
                        $tinymini[ 0 ] =~ s/^A//;
                        $tinymini[ 2 ] =~ s/B$//;
                        my $red = $tinymini[ 1 ];
                        $red =~ s/([^\-]+)\-\1/$1/;
                                                
                        my $tmp2 = "";
                        
                        my $head = $tinymini[ 0 ];
                        my $main = $tinymini[ 1 ];
                        my $tail = $tinymini[ 2 ];
                        
                        
#                        print STDERR "(g): ".$head.$HELPWORD.$tail."\n";
                        if ( !defined( $CACHE{ $head.$HELPWORD.$tail } ) ) {
                            my $result = &findagain( $head, $main, $tail );
                            $CACHE{ $head.$HELPWORD.$tail } = $result;
#                        print STDERR "(x ): ".$token[ $ii ]."||".$parts[ $jj ]."\n";
#                        print STDERR "(h): ".$result."\n";
                        }
                        if ( $CACHE{ $head.$HELPWORD.$tail } !~ m/\_X\-\-/ and !defined( $CACHE{ $main } ) and $main =~ m/\-/ and $head ne "" and $tail ne "" ) {
#                                        print STDERR "(x ): ".$token[ $ii ]."||".$head."||".$main."||".$tail."\n";
                            my $temp = $main;
                            $temp =~ s/([^\-]+)\-.*/$1/g;
                            if ( !defined( $CACHE{ $temp } ) ) {
                                my $result = &findagain2( "", $temp, "" );
                                $CACHE{ $temp } = $result;
                            }
                            my $temp2 = $CACHE{ $temp };
#                            print STDERR "(g ): ".$CACHE{ $temp }."||".$temp2."\n";
                            $temp2 =~ s/^\^//;
                            $temp2 =~ s/\$$//;
                            $temp2 =~ s/$temp//g;
                            $temp2 =~ s/\//CCC/g;
                            $temp2 =~ s/\_...//g;
#                            print STDERR "(g ): ".$CACHE{ $temp }."||".$temp2."\n";
                            $temp = $CACHE{ $temp };
                            $temp =~ s/^\^//;
                            $temp =~ s/\$$//;
#                            $analysis .= "\^".$temp."\$HYPHEN"."\^".$temp."\$HYPHEN";
                            $temp =~ s/(\_.)S(.)/$1P$2/g;
                            $temp =~ s/([^\/]+)\/.*/$1/;
#                            print STDERR "(g ): ||".$temp."\n";
                            $temp .= "(".$temp2.")";
#                            print STDERR "(g ): ||".$temp."\n";
#                            print STDERR "(x ): ||".$temp."\n";
                             $CACHE{ $main } = "\^".$temp."\$";
                        }

                        if ( $CACHE{ $head.$HELPWORD.$tail } !~ m/\_X\-\-/ and !defined( $CACHE{ $main } ) and $main =~ m/\-/ ) {
                                        #print STDERR "(x ): ".$token[ $ii ]."||".$main."\n";
                            my $temp = $main;
                            $temp =~ s/([^\-]+)\-.*/$1/g;
                            if ( !defined( $CACHE{ $temp } ) ) {
                                my $result = &findagain2( "", $temp, "" );
                                $CACHE{ $temp } = $result;
                            }
                            $temp = $CACHE{ $temp };
                            $temp =~ s/^\^//;
                            $temp =~ s/\$$//;
                            $analysis .= "\^".$temp."\$HYPHEN"."\^".$temp."\$HYPHEN";
                        }

                        elsif ( $CACHE{ $head.$HELPWORD.$tail } !~ m/\_X\-\-/ ) {
                            my $one = $CACHE{ $head.$HELPWORD.$tail };
                            if ( !defined( $CACHE{ $main } ) ) {
                                my $result = &findagain2( "", $main, "" );
                                $CACHE{ $main } = $result;
                            }
                            my $two = $CACHE{ $main };
                            $one =~ s/^\^//;
                            $one =~ s/\$$//;
                            $two =~ s/^\^//;
                            $two =~ s/\$$//;

                            if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/  and $one =~ m/$HELPWORD\<.\>\+/) {
                                my $onea = $one;
                                $onea =~ s/($HELPWORD\<.\>)/$1\n/;
                                my @oneb = split( /\n+/, $onea );
                                my $twoa = $two;
                                $twoa =~ s/\_/\n\_/;
                                my @twob = split( /\n+/, $twoa );
                                
                                $two = $twob[ 0 ];
                                $one =~ s/$HELPWORD\<.\>/$two/;
#                                $two = $twob[ 1 ];
#                                $one =~ s/\_.../$two/;

#                                print STDERR "(a): ".$one."||".$two."\n";                
#                                $two =~ s///;
#                                $one =~ s/$HELPWORD\<.\>/$two/;
                            }
                            elsif ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/ ) {
                                $one =~ s/$HELPWORD\<.\>\_.../$two/;
                            }
                            else {
                                $two =~ s/\_...//;
                                $one =~ s/$HELPWORD\<.\>/$two/;
                            }
                            if ( $main =~ m/^([^\-]+)\-\1$/ and $one !~ m/\_.P./ ) {
                                $one =~ s/\_(.)S(.)/\_$1P$2/;
                            }                            

                            $analysis .= "\^".$one."\$HYPHEN";
                        }
                        else {

                            $tmp = $head.$main.$tail;
                            my @part = split( /\-/, $tmp );
                            
                            for ( my $kk = 0; $kk < scalar( @part ); $kk++ ) {
                                if ( defined( $CACHE{ $part[ $kk ] } ) ) {
                                    $analysis .= $CACHE{ $part[ $kk ] }."HYPHEN";
                                }
                                else {
                                    $analysis .= "\^".$part[ $kk ]."\<x\>\_X\-\-\$"."HYPHEN";
                                }
                            }
                        }
                    }
                }
                $analysis =~ s/HYPHEN$//;
                $token[ $ii ] = $analysis;   

#check
#        if ( $token[ $ii ] =~ m/([^\_]+)\$HYPHEN\^([^\_]+)/ ) {
if ( 0 ) {
print STDERR "(i): ".$token[ $ii ]."\n";
            my $ok = $token[ $ii ];
            $ok =~ s/(\^|\$|\+)//g;
            $ok =~ s/\<.\>//g;
            $ok =~ s/\_...//g;
            $ok =~ s/HYPHEN/\-/g;
            $ok =~ s/N//g;
            
            $ok = &smallsegment( "AAA".$ok."AAA" );
            my @wok = split( /SSS/, $ok );
            my $main = $wok[ 1 ];
            
            if ( scalar( @wok ) eq 3 and defined( $CACHE{ $main } ) ) {
                $wok[ 0 ] =~ s/AAA//;
                $wok[ 2 ] =~ s/AAA//;
                
                if ( !defined( $CACHE{ $wok[ 0 ].$HELPWORD.$wok[ 2 ] } ) ) {
                    my $uniquetmp = `echo \$\$`;
                    chomp( $uniquetmp );
                    open( TEMP, ">$Bin/cache-files/$uniquetmp.tmp" );
                    print TEMP "load $Bin/bin-files\/morphind.bin\n";
                    print TEMP "apply up ".$wok[ 0 ].$HELPWORD.$wok[ 2 ]."\n";
                    close( TEMP );
                    my $analysis = `foma -q -f $Bin/cache-files/$uniquetmp.tmp`;
                    chomp( $analysis );
                    my $temp = $wok[ 0 ].$wok[ 1 ].$wok[ 2 ];
                    $temp =~ s/\-//g;
                    $temp = $temp."<x>_X--";
                    $analysis =~ s/\?\?\?/$temp/;

                    $CACHE{ $wok[ 0 ].$HELPWORD.$wok[ 2 ] } = "\^".$analysis."\$";
                    my $command = `rm $Bin/cache-files/$uniquetmp.tmp`;
#                    print STDERR "(0) :".$wok[ 0 ].$HELPWORD.$wok[ 2 ]."\t".$analysis."\n";
                }

                my $one = $CACHE{ $wok[ 0 ].$HELPWORD.$wok[ 2 ] };
                my $two = $CACHE{ $main };
                
                $one =~ s/^\^//;
                $one =~ s/\$$//;
                $two =~ s/^\^//;
                $two =~ s/\$$//;
                            if ( $CACHE{ $head.$HELPWORD.$tail } =~ m/\_[^\_]+\_/ ) {
                                $one =~ s/$HELPWORD\<.\>\_.../$two/;
                            }
                            else {
                                $two =~ s/\_...//;
                                $one =~ s/$HELPWORD\<.\>/$two/;
                            }
                            $analysis .= "\^".$one."\$HYPHEN";
                $token[ $ii ] = "\^".$one."\$";
                $SEEN{ $original } = $token[ $ii ];
                next;
            }
        }

#check
        if ( $token[ $ii ] =~ m/HYPHEN/ and $token[ $ii ] =~ m/\// ) {
            my @part = split( /HYPHEN/, $token[ $ii ] );

            if ( scalar( @part ) == 2 ) {
                my $key = "";
                my $option = "";
                
                if ( $part[ 0 ] !~ m/[\/]/ ) {
                    $key = $part[ 0 ];
                    $option = $part[ 1 ];
                    
                    $key =~ s/^\^//;
                    $key =~ s/\$$//;
                    $key =~ s/(\+[a-z]+)?\_...$//;

                    $option =~ s/^\^//;
                    $option =~ s/\$$//;
                    my @ops = split( /\//, $option );
                    my @resops = ();
                    for ( my $zzz = 0; $zzz < scalar( @ops ); $zzz++ ) {
                        if ( $ops[ $zzz ] =~ m/$key/ ) {
                            push( @resops, $ops[ $zzz ] );
                        }
                    }
                    if ( scalar( @resops ) != 0 ) {
                        $token[ $ii ] = $part[ 0 ]."\$HYPHEN"."\^".join( "/", @resops )."\$";
                    }
                }
                elsif ( $part[ 1 ] !~ m/[\/]/ ) {
                    $key = $part[ 1 ];
                    $option = $part[ 0 ];
                    
                    $key =~ s/^\^//;
                    $key =~ s/\$$//;
                    $key =~ s/(\+[a-z]+)?\_...$//;

                    $option =~ s/^\^//;
                    $option =~ s/\$$//;
                    my @ops = split( /\//, $option );
                    my @resops = ();
                    for ( my $zzz = 0; $zzz < scalar( @ops ); $zzz++ ) {
                        if ( $ops[ $zzz ] =~ m/$key/ ) {
                            push( @resops, $ops[ $zzz ] );
                        }
                    }
                    if ( scalar( @resops ) != 0 ) {
                        $token[ $ii ] = "\^".join( "/", @resops )."\$HYPHEN".$part[ 1 ];
                    }


                }

            }
        }
        
                if ( $token[ $ii ] =~ m/CCC/ ) {
                    my $temp = $token[ $ii ];
                    $temp =~ s/(\<.\>)([^\(]+)(\([^\)]+\))/$1$3$2/;
                    $temp =~ s/^\^([^\(]+)\<.\>\(//;
                    my $head = $1;
                    $temp =~ s/\)([^\)]+)\$$//;
                    my $tail = $1;
                    my @amb = split( /CCC/, $temp );
                    $temp = "";
                    for ( my $k = 0; $k < scalar( @amb ); $k++ ) {
                        $temp .= $head.$amb[$k].$tail."/";
                    }
                    $temp =~ s/\/$//;
                    $token[ $ii ] = "\^".$temp."\$";
                    
                }

                $SEEN{ $original } = $token[ $ii ];
#   print STDERR $token[ $ii ]."::\n".$normalize."::\n".$analysis."||".$head."||".$main."||".$tail."\n";
                next;
            }
        }

    }
                
        
    
    if ( ($i+1) % 1000 eq 0 ) {
        my $c = ( ($i+1) / 1000 ) % 10; 
        print STDERR "".$c;
    }
    

    
    my $resulting_line = "";
    $resulting_line = join( " ", @token );
    #print STDERR "(a): ".$resulting_line."\n";
    $resulting_line = &checkcompound( $lines[ $i ], $resulting_line );
    #print STDERR "(b): ".$resulting_line."\n";
    $resulting_line =~ s/DASH/HYPHEN/g;


    if ( $_DISAMBIGUATE ) {
        # statistical disambiguation
        $resulting_line = &disambiguate( $resulting_line );
    #print STDERR "(c): ".$resulting_line."\n";

        my @chkw = split( /\s+/, $lines[ $i ] ) ;
        my @chkm = split( /\s+/, $resulting_line ) ;
        my $bs = 0;
        if ( scalar( @chkw ) != scalar( @chkm ) ) {
            for ( my $ds = 0; $ds < scalar( @chkw ); $ds++ ) {
                while ( $token[ $ds ] =~ s/HYPHEN|DASH// ) {
                    $chkm[ $bs+1 ] = $chkm[ $bs ]."HYPHEN".$chkm[ $bs+1 ];
                    $chkm[ $bs ] = "";
                    $bs++;
                }
                if ( $chkm[ $bs ] =~ m/DASH/ or $chkm[ $bs ] =~ m/HYPHEN/ ) {
                    $chkm[ $bs ] = &correct( $chkm[ $bs ] );
                }
                $bs++;
            }
        }
        $resulting_line = join( " ", @chkm );
        $resulting_line =~ s/  +/ /g;
        $resulting_line =~ s/^ *//;
        $resulting_line =~ s/ *$//;
        
    }
    
    $resulting_line =~ s/\([^\)\s\_]+\)//g;
    $resulting_line =~ s/(\_[A-Z\-123][A-Z\-123][A-Z\-123])\$\$/$1\$/g;
    $resulting_line =~ s/\$HYPHEN\^/\$DASH\^/g;
    $resulting_line =~ s/HYPHEN/\-/g;
    $resulting_line =~ s/\$\^/\+/g;
    
    


    print $resulting_line."\n";
    
}
        


#foreach my $num ( sort{ $b <=> $a } keys %COMPOUND ) {
#    foreach my $compound ( sort{ $COMPOUND{ $num }{ $a } cmp $COMPOUND{ $num }{ $b } } keys %{$COMPOUND{ $num }} ) {
#        print STDERR $num."\t".$compound."\t".$COMPOUND{ $num }{ $compound }."\n";
#    }
#}


sub correct {
    my $line = $_[ 0 ];
    my $result = $line;

    $line =~ s/\$$//;
    $line =~ s/^\^//;
    
    $line =~ s/HYPHEN/DASH/g;
    
    $line =~ m/(.*)\$DASH\^(.*)/;
    my $head = $1;
    my $tail = $2;
    
    $head =~ s/(\_...)$//;
    my $tag1 = $1;
    my $tag2 = "";
    
    my $test = $head."-".$tail;
    
    $test = "X".&smallsegment( $test )."Y";
    
    if ( $test =~ m/(.*)([YX\+\_\$\^])SSS([^S]+)SSS([YX\+\_\$\^])(.*)/ ) {
        my $flag = $1;
        my $head = $1.$2;
        my $tail = $4.$5;
        my $redup = $3;
        $redup =~ s/([^\-]+)\-\1/$1/;
        $tail =~ s/(\_...)/HERE/;
        $tag2 = $1;
        
        $tag1 =~ s/\_(.)S(.)/\_$1P$2/g;
        $tag2 =~ s/\_(.)S(.)/\_$1P$2/g;
        
        if ( $flag =~ m/X./ ) {
            $tail =~ s/HERE/$tag1/;
        }
        else {
            $tail =~ s/HERE/$tag2/;
        }
        $result = $head.$redup.$tail;
        $result =~ s/[YX]//g;
        $result = "\^".$result."\$";
    }
    $line =~ s/DASH/HYPHEN/g;
    return $result;

}



sub ruleout {
    my $token = $_[ 0 ];
            my $tmp = "";
            
            # chosing ambiguous lemma lexical class, choose the one similar to the resulting POS tag
            #^aku<p>_PS1+rasa<v>+kan_VSA/aku<p>_PS1+rasa<n>+kan_VSA$ = ^aku<p>_PS1+rasa<v>+kan_VSA$
            $tmp = $CACHE{ $token };
            if ( $tmp !~ m/\$[A-Z]+\^/ ) {    
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my @list = sort { $a cmp $b } split( /\//, $tmp );
                $tmp = "\^".join( "/", sort{ $a cmp $b } @list )."\$";
                $CACHE{ $token } = $tmp;
            }

            if ( $tmp =~ m/(.*)(.*)\<(.)\>(.*)\_(...)\/\2\<(.)\>\4\_\5(.*)/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) -1 ; $k++ ) {
                    for ( my $l = $k+1; $l < scalar( @list ) ; $l++ ) {
                        my $s = $list[ $k ]."||".$list[ $l ];
                        if ( $s =~ m/^(.*)\<(.)\>([^\_]*)(\_...)(.*)\|\|\1\<(.)\>\3\4\5$/ ) {                    
                            my $key = lc( substr( $4, 1, 1 ) );
                            my $s1 = $1;
                            my $s2 = $2;
                            my $s3 = $3;
                            my $s4 = $4;
                            my $s5 = $5;
                            my $s6 = $6;
                            if ( $list[ $k ] eq $s1."<".$key.">".$s3.$s4.$s5 ) {
                                $list[ $l ] = $s1."<".$key.">".$s3.$s4.$s5;
                            }
                            elsif ( $list[ $l ] eq $s1."<".$key.">".$s3.$s4.$s5 ) {
                                $list[ $k ] = $s1."<".$key.">".$s3.$s4.$s5;
                            }
                        }
                    }
                }
                my %sorting = ();
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    $sorting{ $list[ $k ] } = 1;
                }
                $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
            }
            
            # chosing ambiguous lemma lexical class, choose the first one
            #^meN+laku<n>+kan_VSA/meN+laku<a>+kan_VSA$ = ^meN+laku<n>+kan_VSA$
            $tmp = $CACHE{ $token };
            if ( $tmp !~ m/\$[A-Z]+\^/ ) {     
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my @list = sort { $a cmp $b } split( /\//, $tmp );
                $tmp = "\^".join( "/", sort{ $a cmp $b } @list )."\$";
                $CACHE{ $token } = $tmp;
            }

            if ( $tmp =~ m/(.*)(.*)\<(.)\>(.*)\_(.)(.)(.)\/\2\<(.)\>\4\_\5\6\7(.*)/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) -1 ; $k++ ) {
                    for ( my $l = $k+1; $l < scalar( @list ) ; $l++ ) {
                        my $s = $list[ $k ]."||".$list[ $l ];
                        if ( $s =~ m/^(.*)\<(.)\>([^\_]*)\_(.)(.)(.)(.*)\|\|\1\<(.)\>\3\_\4\5\6\7$/ ) {                    
                            my $s1 = $1;
                            my $s2 = $2;
                            my $s3 = $3;
                            my $s4 = $4;
                            my $s5 = $5;
                            my $s6 = $6;
                            my $s7 = $7;
                            $list[ $l ] = $s1."<".$s2.">".$s3."_".$s4.$s5.$s6.$s7;
                        }
                    }
                }
                my %sorting = ();
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    $sorting{ $list[ $k ] } = 1;
                }
                $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
            }

        
            # If ambiguous between having a particle or not, choose the one that doesn't have particle
            #^ber+masalah<n>_VSA/ber+masa<n>_VSA+lah<t>_T--$ = ^ber+masalah<n>_VSA$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\_T\-\-/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\_T\-\-/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between having a foreign word + a clitic or a full word, choose the full word
            #^tamu<n>_NSD/ta<f>_F--+kamu<p>_PS2$ = ^tamu<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\_F\-\-\+[^\_]+\_P../ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\_F\-\-\+[^\_]+\_P../ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between having a foreign word + something or a full word, choose the full word
            #^i<f>+kan_VSA/ikan<n>_NSD$ = ^ikan<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\<f\>\+[^\_]+\_/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\<f\>\+[^\_]+\_/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between having a morphem + foreign word or a full word, choose the full word
            #^meN+tang<f>_VSA+dia<p>_PS3/menang<a>_ASP+dia<p>_PS3$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/(meN|pe|per|di|peN|ter|ber)\+[^\<]+\<f\>/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/(meN|pe|per|di|peN|ter|ber)\+[^\<]+\<f\>/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }


            
            # If ambiguous between segmented morpheme and Foreign word, choose foreign word
            #^iri<n>+an_NSD/irian<f>_F--$ = ^irian<f>_F--$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\_F\-\-/ ) {
                        $flagypart = 1;
                    }
                    elsif ( $list[ $k ] =~ m/\+/ and  $list[ $k ] !~ m/\_Z\-\-/ ) {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] =~ m/\_F\-\-/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between 'se+' and a full word, choose a full word
            #^se+karang<n>_ASP/sekarang<d>_D--$ = ^sekarang<d>_D--$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/se\+/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/se\+/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between '+i_' and a full word, choose a full word
            #^astronom<n>+i_VSA/astronomi<n>_NSD$ = ^astronomi<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\+i\_/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\+i\_/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between having a clitic and not, choose not
            #^suku<n>_NSD/su<f>_F--+aku<p>_PS1$ = ^suku<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\+([^\_]+)\_P../ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\+([^\_]+)\_P../ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }


            # If ambiguous between having a clitic and not, choose not
            #^kuat<a>+kan_VSA/aku<p>_PS1+at<f>+kan_VSA$ = ^kuat<a>+kan_VSA$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/([^\_]+)\_P..\+/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/([^\_]+)\_P..\+/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }

            # If ambiguous between plural and marks as foreign, choose plural
            #^di+am<f>_VSP/diam<a>_ASP$ = ^diam<a>_ASP$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ and $token =~ m/([^\s]+)\-\1/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagfpart = 0;
                my $flagopart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\<f\>/ ) {
                        $flagfpart = 1;
                    }
                    else {
                        $flagopart = 1;
                    }
                }
                if ( $flagfpart eq 1 and $flagopart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\<f\>/ ) {
                            $list[ $k ] =~ s/\_(.)S(.)/\_$1P$2/;
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }



            # If ambiguous between plural and not marked plural on token with "-", choose marked
            #^berkat<n>_NPD/berkat<s>_S--$ = ^berkat<n>_NPD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\// and $tmp !~ m/\_Z\-\-/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/([^\_]+)\_.P./ and $token =~ m/\-/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] =~ m/([^\_]+)\_.P./ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between '+an_' and a full word, choose a full word
            #^alasan<n>_NSD/alas<n>+an_NSD$ = ^alasan<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\^([^<]+)\<.\>\+an\_...(\+*[^\/]*)\/\1an\<.\>\_.../ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/\+an\_/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/\+an\_/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between 'di+' and a full word, choose a full word
            #^di+ri<n>_VSP+dia<p>_PS3/diri<n>_NSD+dia<p>_PS3$ = ^diri<n>_NSD+dia<p>_PS3$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\^di\+([^<]+)\<.\>(\+*[^\/]*)\/di\1\<.\>/ or $tmp =~ m/\^([^\_]+\_...\+)di\+([^<]+)\<.\>(\+*[^\/]*)\/\1di\2\<.\>/ ) {

                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/di\+/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/di\+/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between 'peN+' and a full word, choose a full word
            #^peN+duduk<v>_NSD/penduduk<n>_NSD$ = ^penduduk<n>_NSD$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\^peN\+([^<]+)\<.\>(\+*[^\/]*)\/pe(n|ng|)\1\<.\>/ or $tmp =~ m/\^([^\_]+\_...\+)peN\+([^<]+)\<.\>(\+*[^\/]*)\/\1pe(n|ng|)\2\<.\>/ ) {        
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/peN\+/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/peN\+/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                }
            }
            
            # If ambiguous between 'ter+' and a full word, choose a full word
            #^ter+senyum<n>_VSP/tersenyum<v>_VSA$ = ^tersenyum<v>_VSA$
            $tmp = $CACHE{ $token };
            if ( $tmp =~ m/\^ter\+([^<]+)\<.\>(\+*[^\/]*)\/ter\1\<.\>/ or $tmp =~ m/\^([^\_]+\_...\+)ter\+([^<]+)\<.\>(\+*[^\/]*)\/\1ter\2\<.\>/ ) {
                $tmp =~ s/^\^//;
                $tmp =~ s/\$$//;
                my $flagypart = 0;
                my $flagnpart = 0;
                my @list = split( /\//, $tmp );
                for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                    if ( $list[ $k ] =~ m/ter\+/ ) {
                        $flagypart = 1;
                    }
                    else {
                        $flagnpart = 1;
                    }
                }
                if ( $flagypart eq 1 and $flagnpart eq 1 ) {
                    my %sorting = ();
                    for ( my $k = 0; $k < scalar( @list ) ; $k++ ) {
                        if ( $list[ $k ] !~ m/ter\+/ ) {
                            $sorting{ $list[ $k ] } = 1;
                        }
                    }
                    $CACHE{ $token } = "\^".join( "/", sort{ $a cmp $b } keys %sorting )."\$";
                    }
            }
            


}

sub findagain {
    my $head = $_[ 0 ];
    my $main = $_[ 1 ];
    my $tail = $_[ 2 ];
#    print STDERR "fff: \n|".$head."|".$main."|".$tail."|\n\n";        
    my $find = $head.$HELPWORD.$tail;
    
    my $oktemp = $head.$main;
    $oktemp =~ s/\-[^\-]+$//;

    $find =  "apply up ".$find."\necho \#SENTINEL\#\n";
    $find .= "apply up ".$oktemp."\necho \#SENTINEL\#\n";
    $find .= "apply up me".$HELPWORD.$tail."\necho \#SENTINEL\#\n";
    $find .= "apply up pe".$HELPWORD.$tail."\necho \#SENTINEL\#\n";
    $find .= "apply up per".$HELPWORD.$tail."\necho \#SENTINEL\#\n";
    $find .= "apply up ber".$HELPWORD.$tail."\necho \#SENTINEL\#\n";

    
    my $uniquetmp = `echo \$\$`;
    chomp( $uniquetmp );
    open( TEMP, ">$Bin/cache-files/$uniquetmp.tmp" );
    print TEMP "load $Bin/bin-files\/morphind.bin\n";
    print TEMP $find."\n";
    close( TEMP );
    my $result = `foma -q -f $Bin/cache-files/$uniquetmp.tmp`;
    chomp( $result );
    my $command = `rm $Bin/cache-files/$uniquetmp.tmp`;    
#    print STDERR "fff: \n|".$find."|\n\n";    
#    print STDERR "ccc: \n|".$result."|\n\n";

    my ( $analysis, $flag, $meopt, $peopt, $peropt, $beropt ) = split( /\n\#SENTINEL\#/, $result );

    $find = $head.$main.$tail;
    $find =~ s/\-//g;
    $find = $find."<x>_X--";
    
    $analysis =~ s/^\n*//;
    $flag =~ s/^\n*//;
    $meopt =~ s/^\n*//;
    $peopt =~ s/^\n*//;
    $peropt =~ s/^\n*//;
    $beropt =~ s/^\n*//;

    $analysis =~ s/\n*$//;
    $flag =~ s/\n*$//;
    $meopt =~ s/\n*$//;
    $peopt =~ s/\n*$//;
    $peropt =~ s/\n*$//;
    $beropt =~ s/\n*$//;

    
    
    $analysis =~ s/\n/\//g;
    $meopt =~ s/\n/\//g;
    $peopt =~ s/\n/\//g;
    $peropt =~ s/\n/\//g;
    $beropt =~ s/\n/\//g;
    
    $analysis =~ s/\?\?\?/$find/;
    $meopt =~ s/\?\?\?/$find/;
    $peopt =~ s/\?\?\?/$find/;
    $peropt =~ s/\?\?\?/$find/;
    $beropt =~ s/\?\?\?/$find/;
    
    
    if ( $flag =~ m/meN\+/ ) {
        $analysis = "\^".$meopt."\$";                    
    }
    elsif ( $flag =~ m/peN\+/ ) {
        $analysis = "\^".$peopt."\$";                    
    }
    elsif ( $flag =~ m/^per\+/ ) {
        $analysis = "\^".$peropt."\$";                    
    }
    elsif ( $flag =~ m/^ber\+/ ) {
        $analysis = "\^".$beropt."\$";                    
    }
    else {
        $analysis = "\^".$analysis."\$";
    }

#    print STDERR "rrr: \n|".$analysis."|\n\n";        
    return $analysis;
}


sub findagain2 {
    my $head = $_[ 0 ];
    my $main = $_[ 1 ];
    my $tail = $_[ 2 ];
#    print STDERR "fff: \n|".$head."|".$main."|".$tail."|\n\n";        
    my $find = $head.$main.$tail;
    
    $find =  "apply up ".$find."\n";

    
    my $uniquetmp = `echo \$\$`;
    chomp( $uniquetmp );
    open( TEMP, ">$Bin/cache-files/$uniquetmp.tmp" );
    print TEMP "load $Bin/bin-files\/morphind.bin\n";
    print TEMP $find."\n";
    close( TEMP );
    my $analysis = `foma -q -f $Bin/cache-files/$uniquetmp.tmp`;
    chomp( $analysis );
    my $command = `rm $Bin/cache-files/$uniquetmp.tmp`;    
#    print STDERR "fff: \n|".$find."|\n\n";    
#    print STDERR "ccc: \n|".$analysis."|\n\n";

    $find = $head.$main.$tail;
    $find =~ s/\-//g;
    $find = $find."<x>_X--";
    
    $analysis =~ s/^\n*//;
    $analysis =~ s/\n*$//;
    $analysis =~ s/\n/\//g;
    $analysis =~ s/\?\?\?/$find/;
    
    return $analysis;
}


sub strip {
    my $line = $_[ 0 ];
    my $tail = "";
    my $head = "";

    if( defined( $INITCACHE{ $line } ) ) {
        return ( $head, $line, $tail );
    }
    
    foreach my $original ( sort{ $a cmp $b } keys %INITCACHE ) {
        if ( $line =~ m/$original/ and $original =~ m/\-/ ) {
            $line = "AAA".$line."AAA";
            ( $head, $tail ) = split( /$original/, $line );
            $line = $original;
            $head =~ s/^AAA//;
            $tail =~ s/AAA$//;
            return ( $head, $line, $tail );
        }
    }

    while ( $line =~ s/\-?(ku|mu|nya|lah|tah|pun)$// ) {
        $tail = $1.$tail;
        if( defined( $INITCACHE{ $line } ) ) {
            last;
        }
    }
    
    while ( $line =~ s/^(antar|non|anti|ketidak)\-?// ) {
        $head = $head.$1;
        if( defined( $INITCACHE{ $line } ) ) {
            last;
        }
    }

    return ( $head, $line, $tail );
}


sub checkcompound {
    my $src = $_[ 0 ];
    my $mor = $_[ 1 ];
    
    my @ws = split( /\s+/, $src );
    my @ms = split( /\s+/, $mor );
    
    my $temp = "";
    
    for ( my $j = 2; $j <= $MAX_COMPOUND; $j++ ) {
        for ( my $i = 0; $i < scalar( @ws)-$j+1; $i++ ) {
            $temp = "";
            for ( my $k = 0; $k < $j; $k++ ) {
                $temp .= $ws[ $i+$k ]." ";
            }
            $temp =~ s/\s*$//;
            if ( defined( $COMPOUND{ $j }{ $temp } ) ) {

                my @replacement = split( /\s+/, $COMPOUND{ $j }{ $temp } );
                for ( my $k = 0; $k < $j; $k++ ) {
                    $ms[ $i+$k ] = $replacement[ $k ];
                }
            }
        }
    }
    return join( " ", @ms );
}



## If override option is activated
if ( $_OVERRIDE ) {
    foreach my $key ( sort keys %CACHE ) {
        my $dummy = $key;
        $dummy =~ s/DASH/\-/g;
        if( $key =~ m/DASH/ and defined( $CACHE{ $dummy } ) ) {
            delete( $CACHE{ $key } );
        }

        $dummy = $key; 
        $dummy =~ s/^(.*)\1$/$1\-$1/g;
        if( $key =~ m/^(.*)\1$/ and defined( $CACHE{ $dummy } ) and $CACHE{ $key } =~ m/\_X\-\-/ ) {
            delete( $CACHE{ $key } );
        }
    }

    foreach my $key ( sort keys %CACHE ) {
        my $dummy = $key; 
        $dummy =~ s/\-//g;
        if( $key =~ m/\-/ and defined( $CACHE{ $dummy } ) and $CACHE{ $dummy } =~ m/\_X\-\-/ and !defined( $IN{ $dummy } )) {
            delete( $CACHE{ $dummy } );
        }


    }

    open( CACHE, ">$CACHE_FILE" );
    binmode(CACHE, ":utf8");
    foreach my $key ( sort keys %CACHE ) {
        print CACHE $key."\t".$CACHE{ $key }."\n";
    }
    close( CACHE );
}



sub mark_special_char {
    my $key = $_[ 0 ];

    $key =~ s/\-/DASH/g;
    $key =~ s/\+/PLUS/g;
    $key =~ s/\^/CARRET/g;
    $key =~ s/\$/DOLLAR/g;
    $key =~ s/\./DOT/g;
    $key =~ s/\>/GT/g;
    $key =~ s/\</LT/g;

    return $key;
}


sub unmark_special_char {
    my $key = $_[ 0 ];

    $key =~ s/DASH/\-/g;
    $key =~ s/PLUS/\+/g;
    $key =~ s/CARRET/^/g;
    $key =~ s/DOLLAR/\$/g;
    $key =~ s/DOT/\./g;
    $key =~ s/GT/\>/g;
    $key =~ s/LT/\</g;

    return $key;
}

sub disambiguate {

    my $line = $_[ 0 ];  
    $line =~ s/HYPHEN/ /g;
    my @tokens = split( /\s+/, $line );
    
    my $output = "";
    for ( my $i = 0; $i < scalar( @tokens ); $i++ ) {
        
        if ( $tokens[ $i ] =~ m/(\_[A-Z123\-][A-Z123\-][A-Z123\-])\// ) {
            $tokens[ $i ] =~ s/^\^(.*)\$$/$1/g;
            $tokens[ $i ] =~ s/(\_[A-Z123\-][A-Z123\-][A-Z123\-])\//$1\n/g;
            my @ops = split( /\s/,$tokens[ $i ] );
            my %out = ();
            for ( my $j = 0; $j < scalar( @ops ); $j++ ) {
                $out{ "\^".$ops[ $j ]."\$" } = 1;
            }
            $tokens[ $i ] = join( "\n", keys %out );
        }
        
        if ( $i eq 0 ) {
            $output = $tokens[ $i ];
        }
        else {
            my @lines = split( /\n+/, $output );
            if ( $tokens[ $i ] =~ m/\n/ ) {
                $output = "";
                my @intok = split( /\n+/, $tokens[ $i ] );
                for ( my $j = 0; $j < scalar( @lines ); $j++ ) {
                    for ( my $k = 0; $k < scalar( @intok ); $k++ ) {
                        $output .= $lines[ $j ]." ".$intok[ $k ]."\n";
                    }
                }
            }
            else {
                $output = "";
                for ( my $j = 0; $j < scalar( @lines ); $j++ ) {
                    $output .= $lines[ $j ]." ".$tokens[ $i ]."\n";
                }
            }
        }
    }

    $output =~ s/(\_[A-Z123\-][A-Z123\-][A-Z123\-])\+/$1\$ BOO \^/g;
    $output =~ s/\$HYPHEN\^/\$ \^/g;
    chomp( $output );
    if ( $output =~ m/\n/ ) {
        my @candidates = split( /\n+/, $output );
        $output =~ s/ BOO / /g;
        


        $output =~ s/[^\_]*\_([A-Z123\-])[A-Z123\-][A-Z123\-]\$(\s*)/$1$2/g;
        $output =~ s/ +$//;
        my @toscore = split( /\n+/, $output );
        
        my @scores = ();
        my $AMBLIMIT = 500;
        if ( scalar( @toscore ) >= $AMBLIMIT ) {
            $output = "";
            for ( my $ii = 0; $ii < scalar( @toscore ); $ii++ ) {
                if ( ( $ii + 1 ) % $AMBLIMIT ne 0 ) {
                    $output.= $toscore[ $ii ]."\n";
                    next;
                }
                $output.= $toscore[ $ii ]."\n";
            
                my $cmd = `echo "$output" | $QUERY_TOOL $TAG_FILE 2> junk`;
                $cmd =~ s/.*\s+Total:\s+([^\s]+)\s+OOV.*/$1/g;
                @scores = (@scores, split( /\n+/, $cmd ));
#                print $output."\n";
#                print join( " ", @scores )."\n";
                $output = "";
            }
            if ( $output ne "" ) {
                my $cmd = `echo "$output" | $QUERY_TOOL $TAG_FILE 2> junk`;
                $cmd =~ s/.*\s+Total:\s+([^\s]+)\s+OOV.*/$1/g;
                @scores = (@scores, split( /\n+/, $cmd ));
#                print $output."\n";
#                print join( " ", @scores )."\n";
                $output = "";
            }
        }
        else {
            my $cmd = `echo "$output" | $QUERY_TOOL $TAG_FILE 2> junk`;
            $cmd =~ s/.*\s+Total:\s+([^\s]+)\s+OOV.*/$1/g;
            my @scores = split( /\n+/, $cmd );
#                print $output."\n";
#                print join( " ", @scores )."\n";

        }
        
        
        my $max = $scores[ 0 ];
        my $res = 0;
        for ( my $i = 1; $i < scalar( @scores ); $i++ ) {
            if ( $max < $scores[ $i ] ) {
                $res = $i;
                $max = $scores[ $i ];
            }
        }

        $candidates[ $res ] =~ s/\$ BOO \^/\+/g;
        return $candidates[ $res ];
    }
    else {
        $output =~ s/\$ BOO \^/\+/g;
        return $output;
    }
}

sub segmentthis {
    my $line = $_[ 0 ];
    my @words = split( /\s+/, $line );

    for ( my $ii = 0; $ii < scalar( @words ); $ii++ ) {
        $words[ $ii ] =~ s/\-nya$/nya/;
        $words[ $ii ] =~ s/\-mu$/mu/;
        $words[ $ii ] =~ s/\-ku$/ku/;
        my $string = $words[ $ii ];

        if ( $string =~ m/^(\w+)\-\1$/ ) {
           $words[ $ii ] = "TAKETHISA".$string."TAKETHISB";
        }
        elsif ( $string =~ m/\w\-\w/ ) {
            my $MARKER = 0;
            
            my @parts = split( /\-/, $string );
            
            my @partm = ();
            for ( my $i = 0; $i < scalar( @parts )-1; $i++ ) {
                my $a = join( "-", @parts[ 0..($i-1)] )."-";
                my $b = "-".join( "-", @parts[ ($i+2)..(scalar( @parts )-1)] )."-";
                
                
                my $two = $parts[ $i ]."-".$parts[ $i+1 ];
                my $o = "M".$i."aM";
                my $c = "M".$i."bM";
                $two =~ s/([^\-\d\s]+)\-\1/$o$1\-$1$c/;
                $two = $a.$two.$b;
                $two =~ s/^\-*//;
                $two =~ s/\-*$//;
                push( @partm, $two );
#                print " -- ".$two."\n";       
            }
            
        #    for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
        #        print $partm[ $i ]."\n";
        #    }
            
            my @char = split( //, $string );
            my $res = "";
            for ( my $j = 0 ; $j < scalar( @char ); $j++ ) {
                for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
                    while ( $partm[ $i ] =~ s/^(M\d+[a|b]M)// ) {
                        $res .= $1;
                    }
                    $partm[ $i ] =~ s/^.//;
                }
                $res .= $char[ $j ];
            }
            for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
                if ( $partm[ $i ] ne "" ) {
                    $res .= $partm[ $i ];
                }
            }

            
        #    print "RES: ".$res."\n\n";
            
            
            my $choose = -1;
            my @CANDIDATE = ();
            my @PROCESSED = ();
            my $max = -1;
            for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
                my $score = 0;
                $CANDIDATE[ $i ] = $res;
               
                my $a = "M".$i."aM";
                my $b = "M".$i."bM";
                
                $CANDIDATE[ $i ] =~ s/$a/\n$a/g;
                $CANDIDATE[ $i ] =~ s/$b/$b\n/g;
                
                my @tmp = split( /\n+/, $CANDIDATE[ $i ] );
                for ( my $j = 0; $j < scalar( @tmp ); $j++ ) {
                    if ( $tmp[ $j ] =~ m/M(\d+)aM.*M\1bM/ ) {
                        $tmp[ $j ] =~ s/M$1/HERE/g;
                        $tmp[ $j ] =~ s/M\d+[a|b]M//g;
                        
                        my $tmp2 = $tmp[ $j ];
                        $tmp2 =~ s/HEREaM/\nHEREaM/g;
                        $tmp2 =~ s/HEREbM/HEREbM\n/g;  
                        my @tmp3 = split( /\n+/, $tmp2 );
                        for ( my $k = 0; $k < scalar( @tmp3 ); $k++ ) {
                            if ( $tmp3[ $k ] =~ m/HEREaM.*HEREbM/ ) {                
                                $tmp3[ $k ] =~ s/HEREaM//g;
                                $tmp3[ $k ] =~ s/HEREbM//g;
                                $tmp3[ $k ] =~ s/\-//g;
                                $score += length( $tmp3[ $k ] );
                            }
                            
                        }
                        
                    }
                    else {
                        $tmp[ $j ] =~ s/M\d+[a|b]M//g;
                    }
                }
                
                if ( $score >= $max ) {
                    $max = $score;
                    $choose = $i;
                }
                
                $CANDIDATE[ $i ] = join( "", @tmp );
                $CANDIDATE[ $i ] =~ s/HEREaM/TAKETHISA/g;
                $CANDIDATE[ $i ] =~ s/HEREbM/TAKETHISB/g;

                
                
            
            }
            
        #    for ( my $i = 0; $i < scalar( @CANDIDATE ); $i++ ) {
        #        print $CANDIDATE[ $i ]."\n\n";
        #    }
        #    print "CHOOOSE: ".$choose."\n";
        #    print $CANDIDATE[ $choose ]."\n";
            $words[ $ii ] = $CANDIDATE[ $choose ];
            

            
        }
        else {
        #    print $string."\n";
            $words[ $ii ] = $string;
        }
        
    }

    #print join( " ", @words )."\n\n" ;

    for ( my $ii = 0; $ii < scalar( @words ); $ii++ ) {
        my $string = $words[ $ii ];
        
        if ( $string =~ m/^[^\-]*$/ ) {
            # do nothing
        }
        elsif ( $string =~ m/^\-+$/ ) {
            # do nothing
        }
        elsif ( $string =~ m/^[^\-]*TAKETHISA[^A-Z]*TAKETHISB[^\-]*$/) {
            $string =~ s/TAKETHISA//g;
            $string =~ s/TAKETHISB//g;
        }
        else {
            $string =~ s/([^\-]*)TAKETHISA([^\-]+)\-\2TAKETHISB([^\-]*)/$1TAKETHISA$2OOO$2TAKETHISB$3/g;
            my @parts = split( /\-/, $string );
            for ( my $i = 0; $i < scalar( @parts ); $i++ ) {
            
                if ( $parts[ $i ] =~ m/TAKETHISA/ ) {
                    my $score2 = 0;
                    my $score3 = 0;

                    #case 1:
                    my $case2 = $parts[ $i ];
                    $case2 =~ s/OOO/\n/;
                    $case2 =~ s/TAKETHISA//g;
                    $case2 =~ s/TAKETHISB//g;
                    
                    my @items = split( /\n+/, $case2 );
    #                for ( my $j = 0; $j < scalar( @items ); $j++ ) {
    #                    print "\n ::".$items[ $j ];
    #                }
                    $parts[ $i ] = join( "-", @items );
                    
                }
                
                
    #            print "\n :".$parts[ $i ];
            }
            $string = join( "OOO", @parts );
        }
        
        
        
        $words[ $ii ] = $string;
    }
#    print "::".join( " ", @words )."\n";

    return join( " ", @words );

}

sub smallsegment {
    my $string = $_[ 0 ];
        my $MARKER = 0;
        
        my @parts = split( /\-/, $string );
        
        my @partm = ();
        for ( my $i = 0; $i < scalar( @parts )-1; $i++ ) {
            my $a = join( "-", @parts[ 0..($i-1)] )."-";
            my $b = "-".join( "-", @parts[ ($i+2)..(scalar( @parts )-1)] )."-";
            
            
            my $two = $parts[ $i ]."-".$parts[ $i+1 ];
            my $o = "M".$i."aM";
            my $c = "M".$i."bM";
            $two =~ s/([^\-\d\s]+)\-\1/$o$1\-$1$c/;
            $two = $a.$two.$b;
            $two =~ s/^\-*//;
            $two =~ s/\-*$//;
            push( @partm, $two );
#            print $two."\n";       
        }
        
    #    for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
    #        print $partm[ $i ]."\n";
    #    }
        
        my @char = split( //, $string );
        my $res = "";
        for ( my $j = 0 ; $j < scalar( @char ); $j++ ) {
            for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
                while ( $partm[ $i ] =~ s/^(M\d+[a|b]M)// ) {
                    $res .= $1;
                }
                $partm[ $i ] =~ s/^.//;
            }
            $res .= $char[ $j ];
        }
        
        for ( my $i = 0; $i < scalar( @partm ); $i++ ) {
            if ( $partm[ $i ] ne "" ) {
                $res .= $partm[ $i ];
            }
        }

        $res =~ s/M0aM/SSS/g;
        $res =~ s/M0bM/SSS/g;
        return $res;
}



__END__

=head1 NAME

MorphInd - Morphological Analyzer Tools for Indonesian

=head1 SYNOPSIS

  Usage:
   bash$ cat INPUTFILE | perl MorphInd.pl  > OUTPUTFILE
   bash$ echo "mengirim" | perl MorphInd.pl  > OUTPUTFILE
   bash$ cat INPUTFILE | perl MorphInd.pl [-cache-file CACHEFILE -bin-file BINARYFILE -disambiguate (0/1)] > OUTPUTFILE

   Example:
   bash$ cat sample.txt | perl MorphInd.pl > sample.out
   bash$ cat sample.txt | perl MorphInd.pl -cache-file cache-files/default.cache \
        -bin-file bin/morphind.bin -disambiguate 0 > sample.out

   Input example  : "mengirim"
   Output example : "^meN+kirim<v>_VSA$" 
   
   Default values:
       - cache-file     = cache-files/default.cache
       - bin-file       = bin/morphind.bin
       - disambiguate = 0

=head1 DESCRIPTION

This script load the cache file for a pre-analyzed token,
collect the unanalyzed tokens from the input file,
add the analyses in the cache file, and analyzed the input file.
This script also include some additional tagging for the digit, punctuation,
and the unknown tokens as it is not covered by the FST binary file.


=head1 AUTHOR

Septina Dian Larasati
(larasati@ufal.mff.cuni.cz)
(septina.larasati@gmail.com)

=head1 COPYRIGHT

Copyright (c) 2013 Septina Dian Larasati.  All rights reserved.

=head1 SEE ALSO

perl(1).

=cut



