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

. "$CONF_FILE"

function exists()
{
	if [ -z $1 ]; then
		echo -e "Please verify $CONF_PATH/$CONF_FILE" $ERROR
		exit 1
	fi
}

exists ${GLOBAL[setup_path]}
exists ${GLOBAL[ipaddr]}
exists ${GLOBAL[hostname]}
exists ${POSTFIX[config_file]}

# config, value, file
function setconfig()
{
	echo -n "Checking configration ${1}... "
	if grep -q "${1}" "${3}"; then
		echo -e $OK
		sed -r -i 's/^'"${1}"'.*/'"${1}"' = '"${2}"'/g' "${3}"
	else
		echo -e $OK
		echo "${1} = ${2}" >> "${3}"
	fi
}

echo 'Creating backup of the config file ...  '
if ! [ -f "${POSTFIX[config_file]}-$CURRENTDATE" ]; then
	cp ${POSTFIX[config_file]} "${POSTFIX[config_file]}-$CURRENTDATE"
fi 

echo  'Checking Postfix config... '
if [ $? -eq 0 ]; then
	setconfig 'inet_interfaces' 'localhost' ${POSTFIX[config_file]}
	setconfig 'inet_protocols' 'ipv4' ${POSTFIX[config_file]}
	setconfig 'smtpd_timeout' '3600s' ${POSTFIX[config_file]}
	setconfig 'smtpd_proxy_timeout' '3600s' ${POSTFIX[config_file]}
	setconfig 'disable_vrfy_command' 'yes' ${POSTFIX[config_file]}
	setconfig 'message_size_limit' '26214400' ${POSTFIX[config_file]}
	setconfig 'smtp_bind_address' ${GLOBAL[ipaddr]} ${POSTFIX[config_file]}	
	setconfig 'myorigin' '$myhostname' ${POSTFIX[config_file]}
	setconfig 'myhostname' ${GLOBAL[hostname]} ${POSTFIX[config_file]} 
	systemctl restart postfix.service
fi

