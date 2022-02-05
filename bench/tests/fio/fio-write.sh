#!/bin/sh
fio write.fio | tee $(hostname).write.$1.txt

 
