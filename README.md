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
* [MorphInd](http://septinalarasati.com/work/morphind/). Silakan unduh dan pindahkan ke folder morphind sesuai dengan petunjuk direktori di bawah. Harap gunakan versi yang sudah menyediakan parameter 'disambiguate'.

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
Untuk menjalankan program tagger, silakan memanggil skrip `tag.sh` dari direktori tagger. Skrip ini memiliki beberapa parameter yang perlu diperhatikan.
	
	$ ./tag.sh [mode] [input] [verbose]

	mode	:	-file (jika ingin membaca dari suatu berkas)
				-raw (jika ingin langsung menuliskan teks di command line)
	input	:	teks atau ID berkas
	verbose	:	-verbose (jika ingin melihat tahapan proses atau kosongkan saja untuk langsung mengeluarkan hasil akhir)

#### Membaca masukan dari berkas
Silakan buat berkas masukan dalam folder `outputs/` dengan nama `res-[ID berkas]-input.txt`.

    $ cd tagger
    $ echo "Andry makan nasi di rumah sakit kemarin." > outputs/res-[ID berkas]-input.txt

Lalu jalankan perintah ini untuk dapat mengetahui keluarannya.

    $ ./tag.sh -file [ID berkas] -verbose

Atau perintah ini untuk mengeluarkan hasil akhir saja

	$ ./tag.sh -file [ID berkas]

#### Membaca masukan dari command line
Untuk membaca masukan langsung dari command line, silakan jalankan perintah ini.

	./tag.sh -raw "Fam sedang memasak nasi untuk makan" -verbose

Atau perintah ini untuk mengeluarkan hasil akhir saja

	./tag.sh -raw "Fam sedang memasak nasi untuk makan"

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
* [MorphInd](http://septinalarasati.com/work/morphind/). Please make sure to put it in morphind folder. Use the version which allowed 'disambiguate' parameter.

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
You can call the `tag.sh` script to run the tagger from its directory. Please pay attention to the parameters.

	$ ./tag.sh [mode] [input] [verbose]

	mode	:	-file (if you want to read from input file)
				-raw (if you want to read the input from command line)
	input	:	text input or file ID
	verbose	:	-verbose (if you want to debug the process or if you just want to see the result, just leave it blank)

#### Read input from file
Please create an input file in `outputs/` folder by naming it `res-[ID file]-input.txt`

    $ cd tagger
    $ echo "Andry makan nasi di rumah sakit kemarin." > outputs/res-[ID file]-input.txt

Then run the command below to get the result.

     $ ./tag.sh -file [file ID] -verbose

Or this command to get straight to the result.

	$ ./tag.sh -file [file ID]

#### Read input from command line
In order to read the input straight from the command line, please run the command below.

	./tag.sh -raw "Fam sedang memasak nasi untuk makan" -verbose

Or this command to get straight to the result.

	./tag.sh -raw "Fam sedang memasak nasi untuk makan"

You also can run a simple testing script we provided in `testing.sh`. Please make sure this file is executeable.

    $ ./testing.sh


### Authors
- Ruli Manurung
- Arawinda Dinakaramani
- Fam Rashel
- Andry Luthfi 

### License
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.


