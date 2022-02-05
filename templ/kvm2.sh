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


