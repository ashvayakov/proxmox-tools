#!/bin/sh
fio randwrite.fio | tee $(hostname).randwrite.$1.txt

 
