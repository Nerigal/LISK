#!/bin/bash
##############################################
# CSF Firewall - START
##############################################
#
#	Script name:	csf-setup.sh
#	Created on:		11/04/2016
#	Author:			Nerigal Awatt
#	Version:		2.0
#	Purpose:		Iptables manager 
#				more information at http://www.configserver.com/cp/csf.html
#				http://download.configserver.com/csf/readme.txt
#	
#	Hope This script will help you !!
#


(

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



mandatory ${CSF[allow_ipaddr]} 'CSF[allow_ipaddr]'
mandatory ${CSF[ui_user]}  'CSF[ui_user]'
mandatory ${GLOBAL[ipaddr]} 'GLOBAL[ipaddr]'
mandatory ${GLOBAL[setup_path]} 'GLOBAL[setup_path]'

exists ${CSF[alert_email]}  'CSF[alert_email]'
exists ${CSF[LF_ALERT_FROM]} 'CSF[LF_ALERT_FROM]'
exists ${CSF[ui_port]} 'CSF[ui_port]'


if [ -n ${CSF[LF_ALERT_FROM]} ]; then 
    CSF[LF_ALERT_FROM]=`hostname -s`'CSF'@`hostname`
fi 


if [ -f csf.tgz ]; then 
	rm -f csf.tgz
fi

if [ -d csf ]; then
	rm -fr csf/
fi


if ! [ -f /usr/sbin/ipset ]; then
	echo 'Installing ipset'
	if [ -f '/etc/redhat-release' ]; then
        yum install ipset -y
    else
        apt-get install ipset -y 
    fi
fi

# validation prerequisite
if  [ ! -f /usr/sbin/ipset ] && [ ! -f /sbin/ipset ]; then
	echo -n 'could not find ipset, please install ipset... '
	echo -e $ERRORE
	exit 1
fi


cd "$CONF_PATH"
rm -fv csf.tgz
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
bash install.sh


csfconfig=/etc/csf/csf.conf
csfblocklists=/etc/csf/csf.blocklists
csfignore=/etc/csf/csf.ignore
csfallow=/etc/csf/csf.allow
csfpignore=/etc/csf/csf.pignore


echo '# Configuring CSF'
setparam "TESTING =" "TESTING = \"0\"" $csfconfig

echo "${CSF[allow_ipaddr]}" >> $csfallow

echo '# Enable auto updates'
setparam "AUTO_UPDATES =" "AUTO_UPDATES = \"1\"" $csfconfig
echo '# Enable Stateful Packet Inspection (SPI) firewall'
setparam "LF_SPI =" "LF_SPI = \"0\"" $csfconfig
echo '# Enable strict IPV6 ICMP option'
setparam "IPV6_ICMP_STRICT =" "IPV6_ICMP_STRICT = \"1\"" $csfconfig
setparam "IPV6_SPI =" "IPV6_SPI = \"0\"" $csfconfig


sleep 1

if ! grep -q '127.0.0.1' $csfallow; then	
	echo 'Adding localhost to csf.allow'
	echo '127.0.0.1 # localhost' >> $csfallow
fi

setparam "TCP_IN =" "TCP_IN = \"${CSF[TCP_IN]}\"" $csfconfig
setparam "TCP_OUT =" "TCP_OUT = \"${CSF[TCP_OUT]}\"" $csfconfig
setparam "UDP_IN =" "UDP_IN = \"${CSF[UDP_IN]}\"" $csfconfig
setparam "UDP_OUT =" "UDP_OUT = \"${CSF[UDP_OUT]}\"" $csfconfig
setparam "TCP6_IN =" "TCP6_IN = \"${CSF[TCP_IN]}\"" $csfconfig
setparam "TCP6_OUT =" "TCP6_OUT = \"${CSF[TCP_OUT]}\"" $csfconfig
setparam "UDP6_IN =" "UDP6_IN = \"${CSF[UDP_IN]}\"" $csfconfig
setparam "UDP6_OUT =" "UDP6_OUT = \"${CSF[UDP_OUT]}\"" $csfconfig
setparam "USE_CONNTRACK =" "USE_CONNTRACK = \"1\"" $csfconfig
setparam "SYSLOG_CHECK =" "SYSLOG_CHECK = \"300\"" $csfconfig
setparam "DENY_IP_LIMIT =" "DENY_IP_LIMIT = \"5000\"" $csfconfig
setparam "DENY_TEMP_IP_LIMIT =" "DENY_TEMP_IP_LIMIT = \"1000\"" $csfconfig	
setparam "LF_IPSET =" "LF_IPSET = \"1\"" $csfconfig
setparam "LFDSTART =" "LFDSTART = \"1\"" $csfconfig
setparam "SMTP_ALLOWUSER =" "SMTP_ALLOWUSER = \"\"" $csfconfig
setparam "SYNFLOOD =" "SYNFLOOD = \"0\"" $csfconfig
setparam "PORTFLOOD =" "PORTFLOOD = \"0\"" $csfconfig
setparam "DROP_IP_LOGGING =" "DROP_IP_LOGGING = \"0\"" $csfconfig 
setparam "DROP_PF_LOGGING =" "DROP_PF_LOGGING = \"1\"" $csfconfig
setparam "LOGFLOOD_ALERT =" "LOGFLOOD_ALERT = \"1\"" $csfconfig
setparam "LF_ALERT_TO =" "LF_ALERT_TO = \"${CSF[alert_email]}\"" $csfconfig	
setparam "LF_ALERT_FROM =" "LF_ALERT_FROM = \"${CSF[LF_ALERT_FROM]}\"" $csfconfig			
setparam "BLOCK_REPORT = " "BLOCK_REPORT = \"1\"" $csfconfig
setparam "BLOCK_REPORT =" "BLOCK_REPORT = \"1\"" $csfconfig
setparam "LF_PERMBLOCK_INTERVAL =" "LF_PERMBLOCK_INTERVAL = \"86400\"" $csfconfig
setparam "LF_PERMBLOCK_COUNT =" "LF_PERMBLOCK_COUNT = \"10\"" $csfconfig
setparam "SAFECHAINUPDATE =" "SAFECHAINUPDATE = \"1\"" $csfconfig
setparam "CC_INTERVAL =" "CC_INTERVAL = \"1\"" $csfconfig
setparam "LF_POP3D =" "LF_POP3D = \"0\"" $csfconfig
setparam "LF_IMAPD =" "LF_IMAPD = \"0\"" $csfconfig
setparam "LF_WEBMIN_EMAIL_ALERT =" "LF_WEBMIN_EMAIL_ALERT = \"0\"" $csfconfig
setparam "LF_CONSOLE_EMAIL_ALERT =" "LF_CONSOLE_EMAIL_ALERT = \"0\"" $csfconfig
setparam "LF_INTERVAL =" "LF_INTERVAL = \"300\"" $csfconfig
setparam "LF_DIRWATCH_FILE =" "LF_DIRWATCH_FILE = \"60\"" $csfconfig
setparam "LF_DISTFTP =" "LF_DISTFTP = \"1\"" $csfconfig
setparam "LF_DISTFTP_UNIQ =" "LF_DISTFTP_UNIQ = \"5\"" $csfconfig
setparam "PT_USERMEM =" "PT_USERMEM = \"0\"" $csfconfig
setparam "PT_USERTIME =" "PT_USERTIME = \"0\"" $csfconfig
setparam "PT_LOAD_LEVEL =" "PT_LOAD_LEVEL = \"2\"" $csfconfig
setparam "PS_INTERVAL =" "PS_INTERVAL = \"60\"" $csfconfig
setparam "PS_DIVERSITY =" "PS_DIVERSITY = \"5\"" $csfconfig
setparam "AT_ALERT =" "AT_ALERT = \"1\"" $csfconfig
setparam "UI =" "UI = \"1\"" $csfconfig
setparam "UI_PORT =" "UI_PORT = \"${CSF[ui_port]}\"" $csfconfig
setparam "UI_USER =" "UI_USER = \"${CSF[ui_user]}\"" $csfconfig
echo '# Set CSF UI password'
if grep -Pq 'UI_PASS = \"password\"' $csfconfig ;then
		pass=`tr -cd \!A-Za-z0-9 < /dev/urandom | fold -w16 | head -n1`
		echo -e $yellow
		echo 'CSF UI password is... ' $pass
		echo "UI interface is at https://${CSF[allow_ipaddr]}:${CSF[ui_port]}"
		echo -e $NC 
		sed -r -i 's/^#?UI_PASS =.*/UI_PASS = "'$pass'"/g' $csfconfig
	else
		echo 'Password already set'
fi

########################################################## csf.blocklists ########################################################## 
sleep 1
echo 'Configuring Blocklist...'
# Spamhaus Dont Route Or Peer List (DROP)
# Details: http://www.spamhaus.org/drop/

echo 'Spamhaus Dont Route Or Peer List...'
if grep -Pq '^#SPAMDROP.*drop\.lasso' $csfblocklists; then
	echo 'SPAMDROP' $csfblocklists
	sed -r -i 's/^#(SPAMDROP.*drop\.lasso)/\1/g' $csfblocklists			
fi

echo 'Spamhaus Extended DROP List (EDROP)...'
# Details: http://www.spamhaus.org/drop/
if grep -Pq '^#SPAMEDROP.*edrop\.lasso' $csfblocklists; then
	echo 'SPAMEDROP' $csfblocklists
	sed -r -i 's/^#(SPAMEDROP.*edrop\.lasso)/\1/g' $csfblocklists
fi

echo 'DShield.org Recommended Block List...'
# Details: http://dshield.org
if grep -Pq '^#DSHIELD.*' $csfblocklists; then
	echo 'DSHIELD' $csfblocklists
	sed -r -i 's/^#?(DSHIELD.*)/\1/g' $csfblocklists
fi

echo 'TOR Exit Nodes List...'
# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
# Details: https://trac.torproject.org/projects/tor/wiki/doc/TorDNSExitList
if grep -Pq '^#TOR.*' $csfblocklists; then
	echo 'TOR' $csfblocklists
	sed -r -i 's/^#?(TOR.*)/\1/g' $csfblocklists
fi

echo 'Alternative TOR Exit Nodes List...'
# Details: http://torstatus.blutmagie.de/
if grep -Pq '^#ALTTOR.*' $csfblocklists; then
	echo 'ALTTOR' $csfblocklists
	sed -r -i 's/^#?(ALTTOR.*)/\1/g' $csfblocklists
fi

echo 'BOGON list...'
# Details: http://www.team-cymru.org/Services/Bogons/
if grep -Pq '^#BOGON.*' $csfblocklists; then
	echo 'BOGON' $csfblocklists
	sed -r -i 's/^#?(BOGON.*)/\1/g' $csfblocklists
fi

echo 'Project Honey Pot Directory of Dictionary Attacker IPs...'
# Details: http://www.projecthoneypot.org
if grep -Pq '^#HONEYPOT.*' $csfblocklists; then
	echo 'HONEYPOT' $csfblocklists
	sed -r -i 's/^#?(HONEYPOT.*)/\1/g' $csfblocklists
fi

echo 'C.I. Army Malicious IP List...'
# Details: http://www.ciarmy.com
if grep -Pq '^#CIARMY.*' $csfblocklists; then
	echo 'CIARMY' $csfblocklists
	sed -r -i 's/^#?(CIARMY.*)/\1/g' $csfblocklists
fi

echo 'BruteForceBlocker IP List...'
# Details: http://danger.rulez.sk/index.php/bruteforceblocker/
if grep -Pq '^#BFB.*' $csfblocklists; then
	echo 'BFB' $csfblocklists
	sed -r -i 's/^#?(BFB.*)/\1/g' $csfblocklists
fi

echo 'OpenBL.org 30 day List...'
# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
# Details: https://www.openbl.org
if grep -Pq '^#OPENBL.*' $csfblocklists; then
	echo 'OPENBL' $csfblocklists
	sed -r -i 's/^#?(OPENBL.*)/\1/g' $csfblocklists
fi

echo 'Autoshun Shun List...'
# Details: http://www.autoshun.org/
if grep -Pq '^#AUTOSHUN.*' $csfblocklists; then
	echo 'AUTOSHUN' $csfblocklists
	sed -r -i 's/^#?(AUTOSHUN.*)/\1/g' $csfblocklists
fi

echo 'MaxMind GeoIP Anonymous Proxies...'
# Set URLGET in csf.conf to use LWP as this list uses an SSL connection
# Details: https://www.maxmind.com/en/anonymous_proxies
if grep -Pq '^#MAXMIND.*' $csfblocklists; then
	echo 'MAXMIND' $csfblocklists
	sed -r -i 's/^#?(MAXMIND.*)/\1/g' $csfblocklists
fi

echo 'Blocklist.de...'
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
echo 'BDEALL...'
if grep -Pq '^#BDEALL.*' $csfblocklists; then
	echo 'BDEALL' $csfblocklists
	sed -r -i 's/^#?(BDEALL.*)/\1/g' $csfblocklists
fi

echo 'Stop Forum Spam...'
# Details: http://www.stopforumspam.com/downloads/
# Many of the lists available contain a vast number of IP addresses so special
# care needs to be made when selecting from their lists
if grep -Pq '^#STOPFORUMSPAM.*' $csfblocklists; then
	echo 'STOPFORUMSPAM' $csfblocklists
	sed -r -i 's/^#?(STOPFORUMSPAM.*)/\1/g' $csfblocklists
fi

########################################################## END OF csf.blocklists ##################################################

############################################################ csf.pignore #############################################################
echo 'Adding SNMP to process ignore'
setparam "exe:/usr/sbin/snmpd" $csfpignore

##################################################### END OF csf.pignore #############################################################

#
# Reload CSF config
#
if [ -f /etc/csf/csf.error ]; then 
	echo 'Removeing /etc/csf/csf.error'
	rm -f /etc/csf/csf.error
fi

csf -x && csf -e

##############################################
# CSF Firewall - END
##############################################

) 2>&1 | /usr/bin/tee "$CONF_PATH/csf-setup.log" --append


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
	echo '#	I STRONGLY RECOMMAND YOU REVIEW ALL SETTINGS'
	echo '#	https://'${GLOBAL[ipaddr]}':'${CSF[ui_port]}' '
	echo '#'
	echo '# Quick restart csf'
	echo '# csf -x && csf -e > /dev/null'
	echo '# more then that RTFM!!!!1111one'
	echo '# man csf '
	echo '#'
	echo "# Thank you for your vote in advance!!! Nerigal "
	echo '# '
	echo '##################################################################'
	echo -e $NC                                                                                      
fi

########################################################## END OF CSF CONFIG #######################################################
