#!/bin/bash

if [ -f /etc/redhat-release ]
        then
echo "Red Hat"
#Use this script to clean out UUIDs, log files, etc. Final step of setting up a template

echo "Now cleaning up files and removing UUIDs"

#clean up cached yum files
yum clean all

#flush the logs
logrotate –f /etc/logrotate.conf
rm –f /var/log/*-???????? /var/log/*.gz
rm -f /var/log/dmesg.old
rm -rf /var/log/anaconda
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog
cat /dev/null > /var/log/grubby

#remove temp files
rm –rf /tmp/*
rm –rf /var/tmp/*

#remove hardware specific information associated with eth0
sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0

#remove SSH keys
rm –f /etc/ssh/*key*

#remove bash history and SSH history from root user. 
rm -f ~root/.bash_history
unset HISTFILE
rm -rf ~root/.ssh/
rm -f ~root/anaconda-ks.cfg

#reset hostname
# prevent cloudconfig from preserving the original hostname
sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
truncate -s0 /etc/hostname
hostnamectl set-hostname localhost
# set dhcp to use mac - this is a little bit of a hack but I need this to be placed under the active nic settings
# also look in /etc/netplan for other config files
sed -i 's/optional: true/dhcp-identifier: mac/g' /etc/netplan/50-cloud-init.yaml

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

#cleanup shell history
cat /dev/null > ~/.bash_history && history -c
history -w

fi


