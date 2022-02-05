#!/bin/sh
#iozone -Rb am002.$1.xls -s 4g -i 0 -i 1 -i 2 -f /vz/tmp/f1 -r 32k 
time iozone -Rb iozone-am002.$1.xls -a -o -s 4G  -f /vz/tmp/f1 -r 32k | tee iozone-am002.$1.txt
