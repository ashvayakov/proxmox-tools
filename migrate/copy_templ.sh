#! /usr/bin/bash
## ./copy_templ.sh <Templ VEID> <Templ VEID on the desi node> <Name> <Dest node>
VEIDS=$1
DID=$2
DNM=$3
DST=$4
qm clone ${1} ${2} --full --format qcow2 --name ${DNM}
qm template ${DID}
qm migrate ${DID} ${DST}

