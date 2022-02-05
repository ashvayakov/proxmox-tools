#!/bin/bash

if [ -f /etc/redhat-release ]
        then
echo "Red Hat"
#Use this script to clean out UUIDs, log files, etc. Final step of setting up a template

echo "Now cleaning up files and removing UUIDs"

#clean up cached yum files
yum clean all
yum install -y NetworkManager ipcalc
#systemctl disable NetworkManager
#systemctl stop NetworkManager
 
yum install -y qemu-guest-agent

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
apt install subnetcalc -y
apt install network-manager -y
#systemctl enable network-manager
#systemctl start network-manager


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

if [ -f /etc/redhat-release ]
	then
		if [ -f /usr/bin/nmcli ]
	
			then
			echo "nmcli ok"
			else
			yum install -y NetworkManager
            yum install -y qemu-guest-agent
		fi
        systemctl enable NetworkManager
       
		systemctl disable cloud-init	
		systemctl stop cloud-init
        rm -f /etc/NetworkManager/conf.d/99*
        systemctl restart NetworkManager
        sleep 5s	



fi

if [ -f /etc/debian_version ]
	then
               	if [ -f /usr/bin/subnetcalc ]
               		then
			echo "subnetcalc ok"
			else
          		apt install subnetcalc -y
               	fi

		mv /etc/network/interfaces /etc/network/interfaces.bak
		systemctl restart networking	
		systemctl disable cloud-init	
		systemctl stop cloud-init	

 		if [ -f /usr/bin/nmcli ]
	
			then
			echo "nmcli ok"
			else
			yum install network-manager -y 
		fi	      
       
               	systemctl enable network-manager
                systemctl start network-manager
fi
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
			else
			PREF=$(subnetcalc $2 $3 -n  | sed -n '/^Netw/{s#.*/ #/#p;q}')
		fi
	
		IF_NAME=$(nmcli -g NAME c);if [ -z "$IF_NAME" ] 
		then IF_NAME="eth0"
			nmcli con add type ethernet con-name $IF_NAME ifname $IF_NAME 
			systemctl restart networking	
			systemctl restart network-manager	
			fi
		nmcli c mod "${IF_NAME}" ipv4.method manual ipv4.addresses ${2}${PREF}
		nmcli con down "${IF_NAME}"
		nmcli con up "${IF_NAME}"
		echo "IPv4: ${2}${PREF}"
fi

#############################################################
if [ $1 = ipv6 ]
	then

		IF_NAME=$(nmcli -g NAME c);if [ -z "$IF_NAME" ] 
		then IF_NAME="eth0"
			nmcli con add type ethernet con-name $IF_NAME ifname $IF_NAME 
			systemctl restart networking	
			systemctl restart network-manager	
			fi
		nmcli c mod "${IF_NAME}" ipv6.method manual ipv6.addresses ${2}/${3}
		nmcli con down "${IF_NAME}"
		nmcli con up "${IF_NAME}"
		echo "IPv6: ${2}/${3}"
fi

#############################################################

if [ $1 = "ipv4_dns" ]
	then

	IF_NAME=$(nmcli -g NAME c)
	nmcli con mod "${IF_NAME}" +ipv4.dns $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv4 DNS: $2"
fi
#############################################################
if [ $1 = "ipv4_gw" ]
	then	
	IF_NAME=$(nmcli -g NAME c)
	nmcli con mod "${IF_NAME}" ipv4.gateway $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv4 Gateway: $2"
fi

#############################################################
if [ $1 = "ipv6_gw" ]
	then
	IF_NAME=$(nmcli -g NAME c)
	nmcli con mod "${IF_NAME}" ipv6.gateway $2
	nmcli con down "${IF_NAME}"
	nmcli con up "${IF_NAME}"
	echo "IPv6 Gateway: $2"
fi
#
#############################################################

if [ $1 = "ipv6_dns" ]
	then	
	IF_NAME=$(nmcli -g NAME c)
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


EOL

# make sure the script is executable
chmod +x /usr/sbin/kvm



