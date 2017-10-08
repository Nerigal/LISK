#!/bin/bash
#
#	Script name:	postfix-setup.sh
#	Created on:		11/04/2016
#	Author:			Nerigal
#	Version:		0.1
#	Purpose:		MTA 
#	
#	Hope This script will help you !!
#

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
NC='\033[0m' # end of Color tag
OK="[  ${green}OK${NC}  ]"
ERROR="[  ${red}ERROR${NC}  ]"
WARNING="[  ${yellow}WARNING${NC}  ]"

CURRENTDATE=$(date +"%Y-%m-%d")

CONF_PATH='/opt/setup'
CONF_FILE="$CONF_PATH/setup.conf"

mkdir --parent --verbose "$CONF_PATH"
cd "$CONF_PATH"

if ! [ -f "$CONF_FILE" ]; then
	echo -e 'could not find setup.conf file...' 
	wget https://raw.githubusercontent.com/Nerigal/LISK/master/setup.conf -O "$CONF_PATH/setup.conf"
	echo 'Edit the config file to fit your setup and run the install again'
	exit 1
fi

wget https://raw.githubusercontent.com/Nerigal/LISK/master/lib/libShUtil.sh -O "$CONF_PATH/libShUtil"

if [ ! -f './libShUtil' ]; then
    echo 'Could Not find libShUtil'
    exit 1
else
. './libShUtil'
fi

. "$CONF_FILE"

mandatory ${GLOBAL[ipaddr]}
mandatory ${GLOBAL[hostname]}
mandatory ${POSTFIX[config_file]}

echo 'Creating backup of the config file ...  '
if ! [ -f "${POSTFIX[config_file]}-$CURRENTDATE" ]; then
	cp ${POSTFIX[config_file]} "${POSTFIX[config_file]}-$CURRENTDATE"
fi 

echo  'Checking Postfix config... '
if [ $? -eq 0 ]; then
	setparam 'inet_interfaces' 'inet_interfaces = localhost' ${POSTFIX[config_file]}
	setparam 'inet_protocols' 'inet_protocols = ipv4' ${POSTFIX[config_file]}
	setparam 'smtpd_timeout' 'smtpd_timeout = 3600s' ${POSTFIX[config_file]}
	setparam 'smtpd_proxy_timeout' 'smtpd_proxy_timeout = 3600s' ${POSTFIX[config_file]}
	setparam 'disable_vrfy_command' 'disable_vrfy_command = yes' ${POSTFIX[config_file]}
	setparam 'message_size_limit' 'message_size_limit = 26214400' ${POSTFIX[config_file]}
	setparam 'smtp_bind_address' "smtp_bind_address = ${GLOBAL[ipaddr]}" ${POSTFIX[config_file]}	
	setparam 'myorigin' 'myorigin = $myhostname' ${POSTFIX[config_file]}
	setparam 'myhostname' "myhostname = ${GLOBAL[hostname]}" ${POSTFIX[config_file]} 
	systemctl restart postfix.service
fi

