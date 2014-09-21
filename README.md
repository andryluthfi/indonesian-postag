indonesian-postag
=================

Indonesian Named Entity Recognizer

# README.md versi Bahasa
## Pemasangan

untuk memasang anda diharuskan untuk memastikan OS anda dan juga beberapa 
tools atau library di bawah ini terpasang pada mesin anda. 


### Prasyarat Sistem
* Sistem Operasi berbasis Unix.
* Menggunakan Bahasa Pemrograman Perl dan Java (1.6).
* Terpasang [foma](https://code.google.com/p/foma/). Silahkan unduh pada halaman foma dan pastikan terdaftar pada PATH environment variable.
* Unduh [MorphInd](http://septinalarasati.com/work/morphind/). Setelah itu pindahkan folder morphind sesuai dengan skeleton direktori yang disebutkan di bawah.

### Skeleton Direktori
setelah clone repositori ini maka pastikan struktur direktori sebagai berikut:

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

folder tagger didapatkan dari hasil clone repositori ini. 
sedangkan folder morphind didapatkan dari mengunduh [MorphInd](http://septinalarasati.com/work/morphind/).

### Menjalankan Program
silahkan buat file input dalam folder `outputs/` dengan nama `res-[ID file]-input.txt`

    $ cd tagger
    $ echo "Andry makan nasi di rumah sakit kemarin." > outputs/res-[ID file]-input.txt

lalu jalankan perintah ini untuk dapat mengetahui keluarannya

    $ perl NER.pl -f=[ID file]
    $ cat outputs/res-[ID file]-resolved.txt

atau juga dengan menjalakan perintah ini, kami menyiapkan skrip percobaan sebagai demo pada `testing.sh`

    $ ./testing.sh

pastikan berkas tersebut executeable.


# README.md English version


### Authors
- Ruli Manurung
- Arawinda Dinakaramani
- Fam Rashel
- Andry Luthfi 

### License
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.


