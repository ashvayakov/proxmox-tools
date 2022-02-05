#!/bin/sh
fio mix.fio | tee $(hostname).mix.$1.txt

 
