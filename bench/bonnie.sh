#!/bin/sh
bonnie++ -n 0 -u 0 -r `free -m | grep 'Mem:' | awk '{print $2}'` \
-s $(echo "scale=0;`free -m | grep 'Mem:' | awk '{print $2}'`*2" | bc -l) \
-f -b -d /vz/tmp/ > out.csv && cat out.csv | bon_csv2html >boonie.am002.$1.html
#bonnie++ -d /vz/tmp -m 'am004' -u root > out.csv && cat out.csv | bon_csv2html >am004-2.html
 
