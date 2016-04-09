#!/bin/bash
#
#	This file is an Edited version of the default lisk.sh 
#	Done by Nerigal
#
#


red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
NC='\033[0m' # end of Color tag
OK="[ ${green}OK${NC} ]"
ERROR="[ ${red}ERROR${NC} ]"
WARNING="[ ${yellow}WARNING${NC} ]"


BASE_PATH='/usr/local/lisk'
cd ${BASE_PATH}
. "${BASE_PATH}/shared.sh"

if [ ! -f "${BASE_PATH}/app.js" ]; then
  echo -e "Error: Lisk installation was not found. Aborting." ERROR
  exit 1
fi

PATH="${BASE_PATH}/bin:/usr/bin:/bin:/usr/local/bin"
LOG_FILE="${BASE_PATH}/app.log"
PID_FILE="${BASE_PATH}/app.pid"

CMDS=("curl" "node" "sqlite3" "unzip")
check_cmds CMDS[@]

################################################################################

start_forever() {
	download_blockchain
	until node app.js; do
	  echo "Lisk exited with code $?. Respawning..." >&2
	  sleep 3
	done  
}

stop_forever() {
  local PID=$(cat "$PID_FILE")
  if [ ! -z "$PID" ]; then
    kill -- -$(ps -o pgid= "$PID" | grep -o '[0-9]\+') > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "Stopped process $PID " $OK
    else
      echo -e "Failed to stop process $PID " $ERROR
    fi
  fi
  rm -f "$PID_FILE"
}

start_lisk() {
  echo "Starting lisk..."
  if [ -f "$PID_FILE" ]; then
    stop_forever
  fi
  rm -f "$LOG_FILE" logs.log
  touch "$LOG_FILE" logs.log
  start_forever > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo -e "Started process $! " $OK
  RETVAL=$?
}

download_blockchain() {
  if [ ! -f "blockchain.db" ]; then
    echo "Downloading blockchain snapshot..."
    curl -o blockchain.db.zip "https://downloads.lisk.io/blockchain.db.zip"
    [ $? -eq 1 ] || unzip blockchain.db.zip
    [ $? -eq 0 ] || rm -f blockchain.db
    rm -f blockchain.db.zip
  fi
}

stop_lisk() {
  echo "Stopping lisk..."
  if [ -f "$PID_FILE" ]; then
    stop_forever
	RETVAL=$?
  else
    echo -e "Lisk is not running. " $WARNING
  fi
}

check_status() {
  if [ -f "$PID_FILE" ]; then
    local PID=$(cat "$PID_FILE")
  fi
  if [ ! -z "$PID" ]; then
    ps -p "$PID" > /dev/null 2>&1
    local STATUS=$?
	RETVAL=$?
  else
    local STATUS=1
	RETVAL=1
  fi
  if [ -f $PID_FILE ] && [ ! -z "$PID" ] && [ $STATUS -eq 0 ]; then
    echo -e  "Lisk is running (as process $PID). " $OK
  else
    echo -e "Lisk is not running. " $WARNING
  fi
}

RETVAL=0
case $1 in
start)
  start_lisk
  ;;
stop)
  stop_lisk
  ;;
restart|reload|force-reload)
  stop_lisk
  start_lisk
  ;;
status)
  check_status
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: start stop restart autostart rebuild status logs"
  ;;
esac

exit $RETVAL