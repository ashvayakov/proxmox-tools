#!/bin/sh
fio randread.fio | tee $(hostname).randread.$1.txt

 
