indonesian-postag
=================

Indonesian Named Entity Recognizer

# README.md versi Bahasa
## Pemasangan

untuk memasang anda diharuskan untuk memastikan OS anda dan juga beberapa 
tools atau library di bawah ini terpasang pada mesin anda. 


### Prasyarat Sistem
* Sistem Operasi berbasis Unix
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

# README.md English version



