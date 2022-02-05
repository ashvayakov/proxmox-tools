#!/bin/sh
#fio compl.fio | tee $(hostname).compl.$1.txt
fio read.fio | tee $(hostname).read.$1.txt
fio mix.fio | tee $(hostname).mix.$1.txt
fio randread.fio | tee $(hostname).randread.$1.txt
fio randwrite.fio | tee $(hostname).randwrite.$1.txt
fio write.fio | tee $(hostname).write.$1.txt

 
