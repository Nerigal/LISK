#!/bin/bash 


(
#######################################################################################################################################################
#
# INSTALL CentOS 7
#
#######################################################################################################################################################

##

echo
echo "Yum update"
echo
/usr/bin/yum update -y

echo
echo "Yum install"
echo
/usr/bin/yum install -y deltarpm
/usr/bin/yum install -y aide gcc which bc cronie-anacron ntp man iotop ipset vim zip unzip strings strace mlocate mutt wget policycoreutils-python openssh\
perl-Crypt-SSLeay perl-libwww-perl perl-GDGraph perl-LWP-Protocol-https perl-IO-Socket-SSL perl-IO-Socket-INET6 net-snmp net-snmp-utils net-tools iptables \
iptables-services rsyslog tcp_wrappers

grubby --update-kernel=ALL --args="elevator=noop"

cat > /etc/cron.daily/updatedb << EOF_updatedb_script
#! /bin/sh

if [ -x /usr/bin/updatedb ];then
	if [ -f /etc/updatedb.conf ];then
		nice /usr/bin/updatedb
	else
		nice /usr/bin/updatedb -f proc
	fi
fi
EOF_updatedb_script

chmod +x /etc/cron.daily/updatedb

wget https://raw.githubusercontent.com/Nerigal/LISK/master/lib/libShUtil.sh -O "$CONF_PATH/libShUtil"

if [ ! -f './libShUtil' ]; then
    echo 'Could Not find libShUtil'
    exit 1
else
. './libShUtil'
fi

if ! [ -f "$CONF_FILE" ]; then
	echo -e 'could not find setup.conf file...' $WARNING
	wget https://raw.githubusercontent.com/Nerigal/LISK/master/setup.conf -O "$CONF_FILE"
fi


CONF_PATH='/opt/setup'
CONF_FILE="$CONF_PATH/setup.conf"

mkdir --parent --verbose "$CONF_PATH"
cd "$CONF_PATH"


#######################################################################################################################################################

#######################################################################################################################################################
#
# INSTALL CSF FIREWALL
#
#######################################################################################################################################################
#
# Create a working directory 

sleep 3
wget https://raw.githubusercontent.com/Nerigal/LISK/master/csf/csf-setup.sh -O "$CONF_PATH/csf-setup"
bash "$CONF_PATH/csf-setup"


#######################################################################################################################################################
#
# INSTALL POSTFIX SETUP
#
#######################################################################################################################################################
#
# Create a working directory

wget https://raw.githubusercontent.com/Nerigal/LISK/master/postfix-setup.sh -O "$CONF_PATH/postfix-setup"
bash "$CONF_PATH/postfix-setup"


csf -x > /dev/null && csf -e > /dev/null

) 2>&1 | /usr/bin/tee "$CONF_PATH/install-setup.log" --append

