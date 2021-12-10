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

#add check for ssh keys on reboot...regenerate if neccessary
cat << 'EOL' | sudo tee /usr/sbin/kvm
#!/bin/bash

#############################################################


if [ $1 = "password" ]
	then 
	echo "${2}:${3}" | chpasswd
fi
#############################################################
if [ $1 = ipv4 ]
	then
		if [ -f /etc/redhat-release ]
			then
			PREF=$(ipcalc -p $2 $3 | sed -n 's/^PREFIX=\(.*\)/\/\1/p')
            rm -f /etc/NetworkManager/conf.d/99* 2>/dev/null 
            systemctl restart NetworkManager 
			else
			PREF=$(subnetcalc $2 $3 -n  | sed -n '/^Netw/{s#.*/ #/#p;q}')
            
            mkdir /root/tmp	2>/dev/null            
            mv /etc/netplan/* /root/tmp/ 2>/dev/null
            mv /etc/network/interfaces /etc/network/interfaces.bak 2>/dev/null   
            echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg 2>/dev/null 
            echo -e "[keyfile]\nunmanaged-devices=none\n" > /usr/lib/NetworkManager/conf.d/11-fix-managed-devices.conf 2>/dev/null 
            sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf 2>/dev/null 
            echo -e "[keyfile]\nunmanaged-devices=none" > /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf 2>/dev/null 
            systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online 2>/dev/null 
            systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online 2>/dev/null 
            systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online 2>/dev/null 
            systemctl unmask networking 2>/dev/null 
            systemctl enable networking 2>/dev/null 
            systemctl restart networking 2>/dev/null 
            systemctl restart network-manager 

		fi
        rm -f /etc/NetworkManager/conf.d/99* 2>/dev/null	
		PRT1=$(nmcli -f DEVICE d s | grep -v DEVICE | sort -f | head -1)
 
 
		IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
		if [ -z "$IF_NAME" ]
		then
			nmcli con add type ethernet con-name "$PRT1" ifname $PRT1 
			nmcli c mod "${$PRT1}" ipv4.method manual ipv4.addresses ${2}${PREF}
		    nmcli con down "${IF_NAME}"
		    nmcli con up "${IF_NAME}"
		    echo "IP: "$(nmcli -f ipv4.dns,ipv4.addresses,ipv4.gateway con show "${IF_NAME}")""
        else
		    nmcli c mod "${IF_NAME}" ipv4.method manual ipv4.addresses ${2}${PREF}
		    nmcli con down "${IF_NAME}"
		    nmcli con up "${IF_NAME}"
		    echo "IP: "$(nmcli -f ipv4.addresses,ipv4.gateway con show "${IF_NAME}")""
        fi
fi

#############################################################
if [ $1 = ipv4_add ]
	then
        if [ -f /etc/redhat-release ]
			then
			PREF=$(ipcalc -p $2 $3 | sed -n 's/^PREFIX=\(.*\)/\/\1/p')
			else
			PREF=$(subnetcalc $2 $3 -n  | sed -n '/^Netw/{s#.*/ #/#p;q}')
        fi
		IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
		nmcli c mod "${IF_NAME}" ipv4.method manual +ipv4.addresses ${2}${PREF}
		nmcli con down "${IF_NAME}"
		nmcli con up "${IF_NAME}"
		echo "IP: "$(nmcli -f ipv4.addresses,ipv4.gateway con show "${IF_NAME}")""
fi


#############################################################
if [ $1 = ipv6 ]
	then

		IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
		nmcli c mod "${IF_NAME}" ipv6.method manual ipv6.addresses ${2}/${3}
		nmcli con down "${IF_NAME}"
		nmcli con up "${IF_NAME}"
		echo "IPv6: ${2}/${3}"
fi

#############################################################

if [ $1 = "ipv4_dns" ]
	then

	IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
	nmcli con mod "${IF_NAME}" +ipv4.dns $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "DNS: "$(nmcli -f ipv4.dns con show "${IF_NAME}")""
fi
#############################################################
if [ $1 = "ipv4_gw" ]
	then	
	IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
	nmcli con mod "${IF_NAME}" ipv4.gateway $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv4 Gateway: echo IP: "$(nmcli -f ipv4.gateway con show "${IF_NAME}")""
fi

#############################################################
if [ $1 = "ipv6_gw" ]
	then
	IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
	nmcli con mod "${IF_NAME}" ipv6.gateway $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv6 Gateway: $2"
fi
#
#############################################################

if [ $1 = "ipv6_dns" ]
	then	
	IF_NAME="$(nmcli -f CONNECTION d | grep -v "CONNECTION\|--" | sort -f | head -1| sed 's/ *$//g')"
	nmcli con mod "${IF_NAME}" +ipv6.dns $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv4 DNS: $2"
fi
#
#############################################################
if [ $1 = "hostname" ]
        then
        hostnamectl set-hostname ${2}.${3}
        echo "Hostname is now: ${2}.${3}"
fi
#############################################################
if [ $1 = "cid" ]
        then
        systemctl disable cloud-init	
        systemctl stop cloud-init
        systemctl mask cloud-init
        echo "cloud-init disabled"
fi
#############################################################

EOL

# make sure the script is executable
chmod +x /usr/sbin/kvm



