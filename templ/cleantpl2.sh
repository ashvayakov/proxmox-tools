#!/bin/bash

if [ -f /etc/redhat-release ]
        then
echo "Red Hat"
#Use this script to clean out UUIDs, log files, etc. Final step of setting up a template

echo "Now cleaning up files and removing UUIDs"

#clean up cached yum files
yum clean all
yum install -y NetworkManager ipcalc
yum install -y qemu-guest-agent

systemctl enable NetworkManager
systemctl restart NetworkManager
 

 sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
 sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
 sed -i 's/BLACKLIST_RPC/#BLACKLIST_RPC/' /etc/sysconfig/qemu-ga

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

if [ -f /etc/debian_version ]
        then
echo "Debian"
apt install ifupdown -y
systemctl stop apparmor
systemctl disable apparmor
apt remove --assume-yes --purge apparmor

apt install subnetcalc -y
apt install network-manager -y
systemctl enable network-manager
systemctl start network-manager


#Stop services for cleanup
sudo service rsyslog stop

#clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

#cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

#cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

#add check for ssh keys on reboot...regenerate if neccessary
cat << 'EOL' | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# dynamically create hostname (optional)
#if hostname | grep localhost; then
#    hostnamectl set-hostname "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"
#fi
test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL

# make sure the script is executable
chmod +x /etc/rc.local

#reset hostname
# prevent cloudconfig from preserving the original hostname
sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
truncate -s0 /etc/hostname
hostnamectl set-hostname localhost

#cleanup apt
apt clean

# set dhcp to use mac - this is a little bit of a hack but I need this to be placed under the active nic settings
# also look in /etc/netplan for other config files
sed -i 's/optional: true/dhcp-identifier: mac/g' /etc/netplan/50-cloud-init.yaml

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

#cleanup shell history
cat /dev/null > ~/.bash_history && history -c
history -w

#shutdown
#shutdown -h now

fi

IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
nmcli con mod "${IF_NAME}" ipv4.gateway ""
nmcli c mod "${IF_NAME}" ipv4.method manual ipv4.addresses ""


#add check for ssh keys on reboot...regenerate if neccessary

