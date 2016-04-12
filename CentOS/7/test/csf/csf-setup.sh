#!/bin/bash
#
#	Script name:	csf-setup.sh
#	Created on:		11/04/2016
#	Author:			Nerigal
#	Version:		0.3
#	Purpose:		Iptables manager 
#				more information at http://www.configserver.com/cp/csf.html
#				http://download.configserver.com/csf/readme.txt
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

#
# output information about the log file location
#
#
(

if ! [ -f 'setup.conf' ]; then
	echo -e 'could not find setup.conf file...' $WARNING
	exit 1
fi

. 'setup.conf'

function exists()
{
	if [ -z $1 ]; then
		echo -e "Please verify setup.conf" $ERROR
		exit 1
	fi
}                                  

exists ${CSF[alert_email]}
exists ${CSF[LF_ALERT_FROM]}
exists ${CSF[ssl_nat_port]}
exists ${CSF[lisk_port]}
exists ${CSF[alert_email]}
exists ${CSF[ui_user]}
exists ${CSF[ui_port]}
exists ${GLOBAL[ipaddr]}
exists ${GLOBAL[setup_path]}



echo -n 'Checking CSF installtion... '
if [ -f '/etc/csf/csf.conf']; then
	echo -e $OK
else
	echo -e $WARNING 
	echo 'Starting CSF Setup... '
	cd ${GLOBAL[setup_path]} 
	if [ $? -eq 1 ]; then 		
		echo -e 'Setup Folder Not Found' $WARNING
		mkdir --parent --verbose ${GLOBAL[setup_path]} && cd ${GLOBAL[setup_path]}
		if [ $? -eq 0 ]; then
			echo -e $OK
		else
			echo -e $ERROR
		fi
	fi
	
	echo -n 'Checking for old package... '
	if [ -f csf.tgz ]; then 
		echo -e $WARNING
		rm -f csf.tgz
	else
		echo $OK
	fi
	
	echo -n 'Checking for old package... '
	if [ -d csf ]; then
		echo -e $WARNING
		rm -fr csf/
	else
		echo $OK		
	fi

	# validation prerequisite
	if ! [ -f /usr/sbin/ipset ]; then
		echo 'Installing ipset'
		yum install ipset -y
	fi	
fi


# install csf 
wget https://download.configserver.com/csf.tgz

if [ -f csf.tgz ]; then
	echo 'Extracting csf.tgz... '
	tar zxf csf.tgz
	sleep 1
	if [ -d csf ]; then
		cd csf/
		chmod +x ./install.sh
		echo 'Installing csf... '		
		./install.sh &> /dev/null
		
		sleep 1		
		echo 'CSF install Completed... '
		if [ -f /etc/csf/csf.conf ]; then

			csfconfig=/etc/csf/csf.conf
			csfblocklists=/etc/csf/csf.blocklists
			csfignore=/etc/csf/csf.ignore
			csfpignore=/etc/csf/csf.pignore
			csfallow=/etc/csf/csf.allow
			csfuiallow=/etc/csf/ui/ui.allow
			
			echo 'Backing up Config Files... '
			if ! [ -f /etc/csf/csf.conf-$CURRENTDATE ]; then
				cp --verbose $csfconfig /etc/csf/csf.conf-$CURRENTDATE
			fi
			
			if ! [ -f /etc/csf/csf.conf-$CURRENTDATE ]; then
				cp --verbose $csfblocklists /etc/csf/csf.blocklists-$CURRENTDATE
			fi
	
			if ! [ -f /etc/csf/csf.allow-$CURRENTDATE ]; then
				cp --verbose $csfallow /etc/csf/csf.allow-$CURRENTDATE
			fi
	
			if ! [ -f /etc/csf/csf.ignore-$CURRENTDATE ]; then
				cp --verbose $csfignore /etc/csf/csf.ignore-$CURRENTDATE
			fi

			sleep 1
			#####################################################################################################################################

			function add_config()
			{
				if ! grep -q "${1}" $2; then
					echo -e "Adding ${1} to ${2}"  $OK
					if [ -n "$3" ]; then
						echo "${1} # ${3}" >> $2
					else
						echo "${1}" >> $2
					fi
				else
					echo -e "${1} Already set" $WARNING
				fi
			}
			
			
			#-------------------------------------------------------------------------------------------------------------------------------------
			# csf.ignore
			
			echo 'Editing csf.ignore'
			add_config '127.0.0.1' $csfignore 'loopback ip'
			add_config $ipaddr $csfignore 'External ip'
			add_config $mon_ipaddr $csfignore 'External ip'

			#-------------------------------------------------------------------------------------------------------------------------------------

			############################################################ csf.pignore #############################################################

			add_config 'user:lskmark' $csfpignore ''
			add_config 'exe:/usr/local/bin/lisk' $csfpignore ''
			
			##################################################### END OF csf.pignore #############################################################


			############################################################ csf.allow #############################################################
			sleep 1

			# Adding localhost to csf.allow
			add_config '127.0.0.1' $csfallow 'loopback ip'
			
			# Adding External ip to csf.allow 
			add_config $ipaddr $csfallow 'External ip'

			############################################################ END OF csf.allow ######################################################

			# Adding External ip to /etc/csf/ui/ui.allow 
			add_config $ipaddr $csfuiallow 'External ip'

			########################################################## csf.blocklists ########################################################## 
			sleep 1
			# Spamhaus Dont Route Or Peer List (DROP)
			# Details: http://www.spamhaus.org/drop/
			# sed -r -n 's/^(#?SPAMDROP.*)/\1/p' /etc/csf/csf.blocklists
			# sed -r -n 's/^#(SPAMDROP.*)/\1/p' /etc/csf/csf.blocklists
			if grep -Pq '^#SPAMDROP.*drop\.lasso' $csfblocklists; then
				echo 'SPAMDROP' $csfblocklists
				sed -r -i 's/^#(SPAMDROP.*drop\.lasso)/\1/g' $csfblocklists			
			fi
			
			# Spamhaus Extended DROP List (EDROP)
			# Details: http://www.spamhaus.org/drop/
			if grep -Pq '^#SPAMEDROP.*edrop\.lasso' $csfblocklists; then
				echo 'SPAMEDROP' $csfblocklists
				sed -r -i 's/^#(SPAMEDROP.*edrop\.lasso)/\1/g' $csfblocklists
			fi
			
			# DShield.org Recommended Block List
			# Details: http://dshield.org
			if grep -Pq '^#DSHIELD.*' $csfblocklists; then
				echo 'DSHIELD' $csfblocklists
				sed -r -i 's/^#?(DSHIELD.*)/\1/g' $csfblocklists
			fi
			
			# TOR Exit Nodes List
			# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
			# Details: https://trac.torproject.org/projects/tor/wiki/doc/TorDNSExitList
			if grep -Pq '^#TOR.*' $csfblocklists; then
				echo 'TOR' $csfblocklists
				sed -r -i 's/^#?(TOR.*)/\1/g' $csfblocklists
			fi
			
			# Alternative TOR Exit Nodes List
			# Details: http://torstatus.blutmagie.de/
			if grep -Pq '^#ALTTOR.*' $csfblocklists; then
				echo 'ALTTOR' $csfblocklists
				sed -r -i 's/^#?(ALTTOR.*)/\1/g' $csfblocklists
			fi
			
			# BOGON list
			# Details: http://www.team-cymru.org/Services/Bogons/
			if grep -Pq '^#BOGON.*' $csfblocklists; then
				echo 'BOGON' $csfblocklists
				sed -r -i 's/^#?(BOGON.*)/\1/g' $csfblocklists
			fi
			
			# Project Honey Pot Directory of Dictionary Attacker IPs
			# Details: http://www.projecthoneypot.org
			if grep -Pq '^#HONEYPOT.*' $csfblocklists; then
				echo 'HONEYPOT' $csfblocklists
				sed -r -i 's/^#?(HONEYPOT.*)/\1/g' $csfblocklists
			fi

			# C.I. Army Malicious IP List
			# Details: http://www.ciarmy.com
			if grep -Pq '^#CIARMY.*' $csfblocklists; then
				echo 'CIARMY' $csfblocklists
				sed -r -i 's/^#?(CIARMY.*)/\1/g' $csfblocklists
			fi

			# BruteForceBlocker IP List
			# Details: http://danger.rulez.sk/index.php/bruteforceblocker/
			if grep -Pq '^#BFB.*' $csfblocklists; then
				echo 'BFB' $csfblocklists
				sed -r -i 's/^#?(BFB.*)/\1/g' $csfblocklists
			fi

			# OpenBL.org 30 day List
			# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
			# Details: https://www.openbl.org
			if grep -Pq '^#OPENBL.*' $csfblocklists; then
				echo 'OPENBL' $csfblocklists
				sed -r -i 's/^#?(OPENBL.*)/\1/g' $csfblocklists
			fi

			# Autoshun Shun List
			# Details: http://www.autoshun.org/
			if grep -Pq '^#AUTOSHUN.*' $csfblocklists; then
				echo 'AUTOSHUN' $csfblocklists
				sed -r -i 's/^#?(AUTOSHUN.*)/\1/g' $csfblocklists
			fi

			# MaxMind GeoIP Anonymous Proxies
			# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
			# Details: https://www.maxmind.com/en/anonymous_proxies
			if grep -Pq '^#MAXMIND.*' $csfblocklists; then
				echo 'MAXMIND' $csfblocklists
				sed -r -i 's/^#?(MAXMIND.*)/\1/g' $csfblocklists
			fi
			
			# Blocklist.de
			# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
			# Details: https://www.blocklist.de
			# This first list only retrieves the IP addresses added in the last hour
			if grep -Pq '^#BDE.*' $csfblocklists; then
				echo 'BDE' $csfblocklists
				sed -r -i 's/^#?(BDE.*)/\1/g' $csfblocklists
			fi

			# This second list retrieves all the IP addresses added in the last 48 hours
			# and is usually a very large list (over 10000 entries), so be sure that you
			# have the resources available to use it
			if grep -Pq '^#BDEALL.*' $csfblocklists; then
				echo 'BDEALL' $csfblocklists
				sed -r -i 's/^#?(BDEALL.*)/\1/g' $csfblocklists
			fi

			# Stop Forum Spam
			# Details: http://www.stopforumspam.com/downloads/
			# Many of the lists available contain a vast number of IP addresses so special
			# care needs to be made when selecting from their lists
			if grep -Pq '^#STOPFORUMSPAM.*' $csfblocklists; then
				echo 'STOPFORUMSPAM' $csfblocklists
				sed -r -i 's/^#?(STOPFORUMSPAM.*)/\1/g' $csfblocklists
			fi

			########################################################## END OF csf.blocklists ##################################################

			########################################################## CSF Config ##############################################################
			sleep 1
			echo 'Changing config in CSF config file ... '
			sed -r -i 's/^#?TESTING =.*/TESTING = "0"/g' $csfconfig
			sed -r -i 's/^#?AUTO_UPDATES =.*/AUTO_UPDATES = "1"/g' $csfconfig
			sed -r -i 's/^#?LF_SPI =.*/LF_SPI = "1"/g' $csfconfig

			# Allow incoming TCP ports
			sed -r -i 's/^#?TCP_IN =.*/TCP_IN = "53,443,'${CSF[ssl_nat_port]}','${CSF[lisk_port]}'"/g' $csfconfig

			# Allow outgoing TCP ports
			sed -r -i 's/^#?TCP_OUT =.*/TCP_OUT = "53,80,443,'${CSF[ssl_nat_port]}','${CSF[lisk_port]}'"/g' $csfconfig

			# Allow incoming UDP ports
			sed -r -i 's/^#?UDP_IN =.*/UDP_IN = "53"/g' $csfconfig

			# Allow outgoing UDP ports
			# To allow outgoing traceroute add 33434:33523 to this list 
			sed -r -i 's/^#?UDP_OUT =.*/UDP_OUT = "53,123"/g' $csfconfig
			sed -r -i 's/^#?IPV6_ICMP_STRICT =.*/IPV6_ICMP_STRICT = "1"/g' $csfconfig
			sed -r -i 's/^#?IPV6_SPI =.*/IPV6_SPI = ""/g' $csfconfig

			# Allow incoming IPv6 TCP ports
			sed -r -i 's/^#?TCP6_IN =.*/TCP6_IN = "53,443,'${CSF[ssl_nat_port]}','${CSF[lisk_port]}'"/g' $csfconfig

			# Allow outgoing TCP ports
			sed -r -i 's/^#?TCP6_OUT =.*/TCP6_OUT = "53,80,443,'${CSF[ssl_nat_port]}','${CSF[lisk_port]}'"/g' $csfconfig

			# Allow incoming UDP ports
			sed -r -i 's/^#?UDP6_IN =.*/UDP6_IN = "53"/g' $csfconfig
			sed -r -i 's/^#?UDP6_OUT =.*/UDP6_OUT = "53,123"/g' $csfconfig
			sed -r -i 's/^#?USE_CONNTRACK =.*/USE_CONNTRACK = "1"/g' $csfconfig
			sed -r -i 's/^#?SYSLOG_CHECK =.*/SYSLOG_CHECK = "0"/g' $csfconfig
			sed -r -i 's/^#?DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "5000"/g' $csfconfig
			sed -r -i 's/^#?LF_IPSET =.*/LF_IPSET = "1"/g' $csfconfig
			sed -r -i 's/^#?LFDSTART =.*/LFDSTART = "1"/g' $csfconfig
			sed -r -i 's/^#?SMTP_ALLOWUSER =.*/SMTP_ALLOWUSER = ""/g' $csfconfig
			sed -r -i 's/^#?SYNFLOOD =.*/SYNFLOOD = "1"/g' $csfconfig
			sed -r -i 's/^#?PORTFLOOD =.*/PORTFLOOD = "0"/g' $csfconfig
			sed -r -i 's/^#?DROP_IP_LOGGING =.*/DROP_IP_LOGGING = "1"/g' $csfconfig
			sed -r -i 's/^#?DROP_PF_LOGGING =.*/DROP_PF_LOGGING = "1"/g' $csfconfig
			sed -r -i 's/^#?LOGFLOOD_ALERT =.*/LOGFLOOD_ALERT = "1"/g' $csfconfig
			sed -r -i 's/^#?LF_ALERT_TO =.*/LF_ALERT_TO = "'${CSF[alert_email]}'"/g' $csfconfig			
			sed -r -i 's/^#?LF_ALERT_FROM =.*/LF_ALERT_FROM = "'${CSF[LF_ALERT_FROM]}'"/g' $csfconfig			
			sed -r -n 's/^#?BLOCK_REPORT.*/BLOCK_REPORT = "1"/p' /etc/csf/csf.conf 
			sed -r -i 's/^#?BLOCK_REPORT =.*/BLOCK_REPORT = "1"/g' $csfconfig
			sed -r -i 's/^#?LF_PERMBLOCK_INTERVAL =.*/LF_PERMBLOCK_INTERVAL = "86400"/g' $csfconfig
			sed -r -i 's/^#?LF_PERMBLOCK_COUNT =.*/LF_PERMBLOCK_COUNT = "10"/g' $csfconfig
			sed -r -i 's/^#?SAFECHAINUPDATE =.*/SAFECHAINUPDATE = "1"/g' $csfconfig
			sed -r -i 's/^#?CC_INTERVAL =.*/CC_INTERVAL = "1"/g' $csfconfig
			sed -r -i 's/^#?LF_POP3D =.*/LF_POP3D = "0"/g' $csfconfig
			sed -r -i 's/^#?LF_IMAPD =.*/LF_IMAPD = "0"/g' $csfconfig
			sed -r -i 's/^#?LF_WEBMIN_EMAIL_ALERT =.*/LF_WEBMIN_EMAIL_ALERT = "0"/g' $csfconfig
			sed -r -i 's/^#?LF_CONSOLE_EMAIL_ALERT =.*/LF_CONSOLE_EMAIL_ALERT = "0"/g' $csfconfig
			sed -r -i 's/^#?LF_INTERVAL =.*/LF_INTERVAL = "300"/g' $csfconfig
			sed -r -i 's/^#?LF_DIRWATCH_FILE =.*/LF_DIRWATCH_FILE = "60"/g' $csfconfig
			sed -r -i 's/^#?LF_DISTFTP =.*/LF_DISTFTP = "1"/g' $csfconfig
			sed -r -i 's/^#?LF_DISTFTP_UNIQ =.*/LF_DISTFTP_UNIQ = "5"/g' $csfconfig
			sed -r -i 's/^#?PT_USERMEM =.*/PT_USERMEM = "500"/g' $csfconfig
			sed -r -i 's/^#?PT_USERTIME =.*/PT_USERTIME = "14400"/g' $csfconfig
			sed -r -i 's/^#?PT_LOAD_LEVEL =.*/PT_LOAD_LEVEL = "2"/g' $csfconfig
			sed -r -i 's/^#?PS_INTERVAL =.*/PS_INTERVAL = "60"/g' $csfconfig
			sed -r -i 's/^#?PS_DIVERSITY =.*/PS_DIVERSITY = "5"/g' $csfconfig
			sed -r -i 's/^#?AT_ALERT =.*/AT_ALERT = "1"/g' $csfconfig
			sed -r -i 's/^#?UI = "0"/UI = "1"/g' $csfconfig
			sed -r -i 's/^#?UI_PORT =.*/UI_PORT = "'${CSF[ui_port]}'"/g' $csfconfig
			sed -r -i 's/^#?UI_USER =.*/UI_USER = "'${CSF[ui_user]}'"/g' $csfconfig

			if grep -Pq 'UI_PASS = \"password\"' $csfconfig ;then
				pass=`tr -cd \!A-Za-z0-9 < /dev/urandom | fold -w16 | head -n1`
				echo 'CSF UI password is... ' $pass
				sed -r -i 's/^#?UI_PASS =.*/UI_PASS = "'$pass'"/g' $csfconfig
			else
				echo 'Password already set'
			fi
		fi # if config file
	fi # if csf folder exist
fi # if csf.tgz

csf -x && csf -e
RETVAL=$?
echo 

) 2>&1 | /usr/bin/tee /root/setup/csf-setup.log --append


if [[ $RETVAL -eq 0 ]]; then
	echo -e $yellow
	echo '##################################################################'
	echo '#'
	echo '# ConfigServer & Security Firewaal is installed'
	echo '# Make sure you have access to your interface at https://'${GLOBAL[ipaddr]}':'${CSF[ui_port]}''
	echo '# This script has setup a vary basic configuration'
	echo '# I strongly recommand to reveiw all the setting to fit to your needs'
	echo '# You can find more information at http://configserver.com/cp/csf.html'
	echo '#'
	echo '#	>>> THIS IS A MINIMAL CONFIG <<<'
	echo '#	ISTRONGLY RECOMMAND YOU REVIEW ALL SETTINGS'
	echo '#	https://'${GLOBAL[ipaddr]}':'${CSF[ui_port]}' '
	echo '#'
	echo '# Quick restart csf'
	echo '# csf -x && csf -e > /dev/null'
	echo '# more then that RTFM!!!!1111one'
	echo '# '
	echo "# Thank you for your vote in advance!!! Nerigal "
	echo '# '
	echo '##################################################################'
	echo -e $NC                                                                                      
fi


########################################################## END OF CSF CONFIG #######################################################
# Good Song !! 
# https://www.youtube.com/watch?v=M_TBENcax_g
# https://www.youtube.com/watch?v=ZMbFu457jGs
# https://www.youtube.com/watch?v=KBuiI1lNO-s
#


