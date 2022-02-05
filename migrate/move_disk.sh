#!/bin/bash

DEST=$1
for VEIDD in $(cat mvd.list) 
do

for HDD in $(qm config ${VEIDD} | grep ^"scsi\|sata\|ide\|virtio"| grep -v "hw\|cdrom\|net" | cut -d ":" -f1)
do
echo $HDD - $DEST


qm move_disk --delete=1 ${VEIDD} ${HDD} ${DEST}
done
done 
