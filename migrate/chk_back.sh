#! /usr/bin/bash

for VEIDS in $(qm list | grep running | awk '{print $1}')
do

qm config ${VEIDS} | grep Backups


done

