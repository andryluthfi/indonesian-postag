indonesian-postag
=================

Indonesian Rule-Based Part-of-Speech Tagger
* [Bahasa](#readmemd-versi-bahasa).
* [English](#readmemd-english-version).

# README.md versi Bahasa
## Pemasangan

Untuk menggunakan Rule-Based POS Tagger Bahasa Indonesia anda harus memastikan tools atau library di bawah ini terpasang pada OS anda. 


### Prasyarat Sistem
* Sistem Operasi berbasis Unix
* Perl
* Java (1.6)
* [foma](https://code.google.com/p/foma/). Silakan unduh dan pastikan terdaftar pada PATH environment variable.
* [MorphInd](http://septinalarasati.com/work/morphind/). Silakan unduh dan pindahkan ke folder morphind sesuai dengan petunjuk direktori di bawah.

### Skeleton Direktori
Setelah clone repositori ini, pastikan struktur direktori sebagai berikut:

    indonesian-tagger/
    |-- tagger 
    |   |-- NER.pl
    |   |-- testing.sh
    |   `-- ...
    `-- morphind
        |-- MorphInd.pl
        |-- bin-files
        |   |-- morphind.bin
        |   `-- ...
        `-- cache-files
            |-- 2432.tmp
            `-- ...

Folder `tagger` didapatkan dari hasil clone repositori ini sedangkan folder `morphind` didapatkan dari mengunduh [MorphInd](http://septinalarasati.com/work/morphind/).

### Menjalankan Program
Silakan buat file input dalam folder `outputs/` dengan nama `res-[ID file]-input.txt`.

    $ cd tagger
    $ echo "Andry makan nasi di rumah sakit kemarin." > outputs/res-[ID file]-input.txt

Lalu jalankan perintah ini untuk dapat mengetahui keluarannya.

    $ perl NER.pl -f=[ID file]
    $ cat outputs/res-[ID file]-resolved.txt

Anda juga dapat menjalakan skrip percobaan yang kami sediakan pada `testing.sh`. Pastikan berkas tersebut executeable.

    $ ./testing.sh


# README.md English version
## Installation

In order to use Indonesian Rule-Based POS Tagger, you need to make sure your Operating System have the tools and library below installed. 


### System Requirements
* Unix Operating System
* Perl 
* Java (1.6)
* [foma](https://code.google.com/p/foma/). Please make sure foma was registered in your PATH environment variable.
* [MorphInd](http://septinalarasati.com/work/morphind/). Please make sure to put it in morphind folder.

### Directory Skeleton
After you clone the repository, the directory structure should look like this:

    indonesian-tagger/
    |-- tagger 
    |   |-- NER.pl
    |   |-- testing.sh
    |   `-- ...
    `-- morphind
        |-- MorphInd.pl
        |-- bin-files
        |   |-- morphind.bin
        |   `-- ...
        `-- cache-files
            |-- 2432.tmp
            `-- ...

You would get `tagger` folder after cloning the repository. 
You should get `morphind` folder by downloading [MorphInd](http://septinalarasati.com/work/morphind/).

### Running The Program
Please create an input file in `outputs/` folder by naming it `res-[ID file]-input.txt`

    $ cd tagger
    $ echo "Andry makan nasi di rumah sakit kemarin." > outputs/res-[ID file]-input.txt

Then run the command below to get the result.

    $ perl NER.pl -f=[ID file]
    $ cat outputs/res-[ID file]-resolved.txt

You also can run a simple testing script we provided in `testing.sh`. Please make sure this file is executeable.

    $ ./testing.sh


### Authors
- Ruli Manurung
- Arawinda Dinakaramani
- Fam Rashel
- Andry Luthfi 

### License
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.


