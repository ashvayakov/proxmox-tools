#!/bin/bash -x

#HOST=$(hostname -f)
HOST=$(ifconfig eth0|grep addr:|sed 's/.*addr:\([^ ]*\) .*/\1/')
SERV2="77.72.128.115"
#chmod 777 /etc/drupal/6/sites/default/dbconfig.php
#ab -k -n 25 -c 10 http://localhost/drupal6/ > /root/tests/$HOST.PHP.www.txt 2>/dev/null
#ab -k -n 50 -c 5 http://localhost/ > /root/tests/$HOST.STAT.www.txt 2>/dev/null
#Пауза
#sleep 5;
##Нагрузка на диск
#dd if=/dev/zero of=/file.bin bs=1024000 count=100
#mkdir /test || 

#rsync --bwlimit=5000 -v -a /srv/* /test/ > /root/tests/$HOST.hdd.txt 2>&1
#rsync -v -a /srv/* /test/ > /root/tests/$HOST.hdd.txt 2>&1
rsync -v -a /lib/modules/2.6.32-5-amd64/* /test/ > /root/tests/$HOST.hdd.txt 2>&1
#/root/tests/unixbench-4.1.0-wht-2/Run
#scp $SERV2:/xenskel/var/www/pts.png /var/www/
scp /root/tests/*.txt $SERV2:/root/tests/reports/
rm -f /root/tests/*.txt
rm -Rf /test/*


 
