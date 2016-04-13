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


ARCK=`uname -m`
CURRENTDATE=$(date +"%Y-%m-%d")
CONFIG_FILE='/opt/lisk/client/config.json'
CURRENT_VERSION=`sed -r -n 's/\"version\"\:\s+?\"([0-9\.]+)\"\,/\1/p' $CONFIG_FILE | xargs`
LISK_NETWORK='test'

new_version=($(wget -q -O - https://downloads.lisk.io/lisk/$LISK_NETWORK/ | perl -nle ' print "$+{version}" if /.*(?<fullname>lisk-(?<version>[0-9\.]+)-Linux-(?<ARCK>'$ARCK')\.zip).*/' | sort -r -V))

function check_version()
{
    
	if [[ $1 == $2 ]]
    then
        return 0
    fi
	
    local IFS=.
    local i ver1=($1) ver2=($2)    
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

check_version $CURRENT_VERSION $new_version
case $? in
 0) return 0;;
 1) # Trigger update process here ;;
esac

