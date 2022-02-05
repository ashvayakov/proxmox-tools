#!/bin/sh
fio read.fio | tee $(hostname).read.$1.txt

 
