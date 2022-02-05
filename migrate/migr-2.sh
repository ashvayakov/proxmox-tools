#! /usr/bin/bash

VEIDS=$1
DEST="kfn2-node2"

for CD in $(qm config ${VEIDS} | grep cdrom | cut -d: -f 1)
        do
        qm set ${VEIDS} --${CD} none,media=cdrom
        done


qm migrate ${VEIDS} ${DEST} --online --with-local-disks | mail -s "Migration VE-${VEIDS}" events@keyfinanz.de
ssh ${DEST} qm set ${VEIDS} --ide2 Backups:cloudinit

