#!/bin/bash
#
#	Script name:	check-update.sh
#	Created on:		12/04/2016
#	Author:			Nerigal
#	Version:		0.1
#	Purpose:		auto update using cron task 
#	
#	Hope This script will help you !!
#

### EDIT AND FIT TO YOUR NEEDS ###
ARCK=`uname -m`
CURRENTDATE=$(date +"%Y-%m-%d")
CONFIG_FILE='/opt/lisk/client/config.json'
CURRENT_VERSION=`sed -r -n 's/\"version\"\:\s+?\"([0-9\.]+)\"\,/\1/p' $CONFIG_FILE | xargs`
LISK_NETWORK='test'



new_version=($(wget -q -O - https://downloads.lisk.io/lisk/$LISK_NETWORK/ | perl -nle ' print "$+{version}" if /.*(?<fullname>lisk-(?<version>(?:[0-9\.]+|latest))-Linux-(?<ARCK>'$ARCK')\.zip).*/' | sort -r -V))

if [ -z $new_version ]; then
	echo 'Could not retrive version number'
	exit 1
fi 

function check_version()
{
    
	if [[ $1 == $2 ]]; then
		return 0
	fi

	result=$2
	IFS=.
	ver1=($1)
	ver2=($2)
	
	if [ ${#ver1[@]} -lt ${#ver2[@]} ]; then
		ver1+=(0)
	fi	
	
	for ((i=0; i<${#ver1[@]}; i++))
	do

		if [[ "${ver2[i]}" -lt "${ver1[i]}" ]]; then
			return 0
		fi
		
		if [[ "${ver2[i]}" -gt "${ver1[i]}" ]]; then
			echo "$result"
			break;
		fi
	done
	return 0
}


update=`check_version $CURRENT_VERSION $new_version`
if ! [ -z $update ]; then
	echo "Starting Lisk Update process to version $update"
	### TRIGGER YOUR UPDATE TASK HERE ###
fi


