#! /usr/bin/bash

for VEIDS in $(qm list | grep running | awk '{print $1}')
do

for CD in $(qm config ${VEIDS} | grep cdrom |head -1 | cut -d: -f 1)
	do
		#qm config ${VEIDS} | grep Backups	
		qm set ${VEIDS} --${CD} Backups:cloudinit
		#echo "${VEIDS} --${CD} none,media=cdrom"
	done

done

