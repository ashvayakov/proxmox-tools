#! /usr/bin/bash
## ./copy_templ_all.sh <Templ VEID>
VEIDS=$1
DNM="$(qm config  ${VEIDS} | grep name | cut -d ":" -f 2)"
echo $DNM
for DS in 1 2 4
do
  DST="kfn2-node${DS}"
  DID="${DS}${VEIDS}"
  #echo $DID
  qm clone ${VEIDS} ${DID} --full --format qcow2 --name ${DNM}
  qm template ${DID}
  qm migrate ${DID} ${DST}
done

