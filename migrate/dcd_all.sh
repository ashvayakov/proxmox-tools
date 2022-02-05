#! /usr/bin/bash

for VEIDS in $(qm list | grep running | awk '{print $1}')
do

for CD in $(qm config ${VEIDS} | grep Backups|grep cdrom | cut -d: -f 1)
	do
		qm set ${VEIDS} --${CD} none,media=cdrom
	done

done

