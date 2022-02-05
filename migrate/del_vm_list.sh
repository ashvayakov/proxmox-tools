#!/bin/bash

DEST=$1
for VEIDD in $(cat delvm.list) 
do

qm destroy ${VEIDD}
done 
