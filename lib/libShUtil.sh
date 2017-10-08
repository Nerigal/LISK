#!/bin/bash
#-----------------------
#   Bash lib to simplify usage of parameter function
#
#   Script name:    setup.conf
#   Created on:     15/04/2016
#   Author:         Nerigal Awatt
#
#-----------------------


red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
NC='\033[0m' # end of Color tag
OK="[  ${green}OK${NC}  ]"
ERROR="[  ${red}ERROR${NC}  ]"
WARNING="[  ${yellow}WARNING${NC}  ]"


#--------------------------------------------------------------------------------------------
function mandatory()
{
	if [ -z $1 ]; then
		echo -e "Please verify setup.conf ${2}" $ERROR
		exit 1
	fi
}
#--------------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------------
function exists()
{
	if [ -z $1 ]; then
		echo -e "You should consider configuring ${2} in Setup.conf"  $ERROR
		exit 1
	fi
}
#--------------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------------
function CheckStatusCode()
{
    if [[ $? -eq 1 ]]; then 
        echo -e "$ERROR "
        exit 1
    else
        echo -e "$OK "
    fi
}
#--------------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------------
function setparam()
{
    if [ ! -z $4 ] ;then
        if grep -E -q "^#?$1.*" $4 &> /dev/null ;then            
            sed -i -r "s|^#?$1.*|$2|g" $4
        else
            echo "$3" >> $4 2>&1
        fi
    fi

    
    # param $1 search string 
    # param $2 replacement
    # param $3 file path
    if [[ ! -z "$3"  &&  -z "$4" ]];then
        if grep -E -q "^#?$1.*" $3 &> /dev/null || grep -E -q ".*$2.*" $3 &> /dev/null; then
            if grep -E -q "$2" $3 &> /dev/null ;then
                echo -e "$WARNNING Parameter $2 already set..."
            else
                sed -i -r "s|^#?$1.*|$2|g" $3
                if [ $? -eq 0 ];then
                    echo -e "$OK Value [ $1 ] has been replace by [ $2 ] correctly in [ $3 ]"
                else
                    echo -e "$ERROR Could not execute the Sed command correctly in [ $2 ], Value to be replaced [ $1 ], Please investigate..."
                fi              
            fi            
        else
            echo -e "$WARNNING Parameter $1 not found in $3, it will be added..."
            echo "$2" >> $3
        fi
    fi


    # param $1 search string 
    # param $2 file path
    if [[ ! -z "$2"  &&  -z "$3" ]];then 
        if grep -q "$1" $2 &> /dev/null ; then
            echo -e "$WARNING Value [ $1 ] already set in $2, Nothing to do... "
        else
            if grep -E -q "^#?$1.*" $2 &> /dev/null ; then
                sed -i -r "s|^#?$1.*|$1|g" $2
                if [ $? -eq 0 ];then 
                    echo -e "$OK Value [ $1 ] have been set correctly in [ $2 ]"
                else
                    echo -e "$ERROR Value [ $1 ] Could not execute the Sed command correctly in [ $2 ], Please investigate..."
                fi
            else
                echo "$1" >> $2
                if [ $? -eq 0 ];then 
                    echo -e "$OK Value [ $1 ] have been set correctly in [ $2 ]"
                else
                    echo -e "$ERROR Value [ $1 ] Could not be set correctly in [ $2 ], Please investigate..."
                fi
            fi
        fi
    fi
}
#--------------------------------------------------------------------------------------------

