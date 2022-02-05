#! /usr/bin/bash

DEST="kfn2-node1"
for VEIDS in $(qm list | grep running | awk '{print $1}')
do

for CD in $(qm config ${VEIDS} | grep cdrom | cut -d: -f 1)
	do
		qm set ${VEIDS} --${CD} none,media=cdrom
	done

	qm migrate ${VEIDS} ${DEST} --online --with-local-disks | mail -s "Migration VE-${VEIDS}" events@keyfinanz.de
done

