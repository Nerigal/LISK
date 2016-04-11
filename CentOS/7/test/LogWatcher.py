#!/usr/bin/env python
#	Script name:    LogWatcher.py
#	Created on:     08/04/2016
#	Author:         Nerigal
#	Version:        0.1
#	Purpose:		Real time scan lisk log file for custom events trigger
#
#============= How To Use =============
#
#	Save this file in /opt/tools/lisk/watcher.py
#	To run the script in shell mode:
#	cd /opt/tools/lisk/
#	python watch.py
#
#	To run in background:
#	python /opt/tools/lisk/watcher.py &> /dev/null &
#====================================================================================================

import os
import re
import json
import datetime
import subprocess
from time import sleep

#====================================================================================================
class Execute:
 #----------------------------------------------------------------------------------------------------
 def re_task(self, obj):
  print(obj.group(1))
 #----------------------------------------------------------------------------------------------------

 #----------------------------------------------------------------------------------------------------
 def json_task(self, obj, publicKey):
  if obj['level'] == 'error':
   print(obj['message'])
  if obj['level'] == 'info':
   print json.dumps(obj, sort_keys=True, indent=4, separators=(',', ': '))
  if 'Fork' in obj['message']: 
   for idx, val in enumerate(obj, start=0):
    val = val.rstrip('u')
    if val == 'data':
     if 'delegate' in obj['data']:
      delegate = obj[val]['delegate']
      print 'Forked Delegate ' + delegate
      if delegate ==  publicKey:
       subprocess.check_call(["/opt/tools/lisk/rebuild.sh", stdin=None, stdout=None, stderr=None, shell=False])
       print('LISK rebuild executed')
 #----------------------------------------------------------------------------------------------------

#====================================================================================================

#====================================================================================================
class log_watcher:

 #----------------------------------------------------------------------------------------------------
 def __init__(self, logfile, obj, publicKey):
  self.logfile = logfile
  self.obj = obj
  self.rusage_denom = 1024
  self.external = Execute()
  self.publicKey = publicKey
 #----------------------------------------------------------------------------------------------------

 #----------------------------------------------------------------------------------------------------
 def log_manager(self):
  fo = open(self.logfile, "r")
  fo.seek(0,os.SEEK_END)
  file_length = fo.tell()
  pos = file_length
  passcount = 0
  while True:
   if not os.access(self.logfile, os.F_OK) and os.access(self.logfile, os.R_OK):
    #fo.close()
    break   
   fo.seek(0, os.SEEK_END)
   endpos = fo.tell()
   lines = []
   if pos < endpos:
    fo.seek(pos,0)
    lines = fo.readlines()
    if lines:
     for line in lines:
      self.line = line.rstrip('\n\r')
      if self.obj == 'json':
       self.internal = self.log_jsonparser()
      else:
       self.internal = self.log_reparser()
    pos = fo.tell()
    sleep(1)
   else:
    passcount += 1
   if passcount >= 20:
    fo.close()
    sleep(10)
    passcount = 0
    fo = open(self.logfile,"r")
   sleep(0.05)
 #----------------------------------------------------------------------------------------------------

 #----------------------------------------------------------------------------------------------------
 def log_reparser(self, regex):
  self.external.re_task(re.match(self.regex, self.line))
 #----------------------------------------------------------------------------------------------------

 #----------------------------------------------------------------------------------------------------
 def log_jsonparser(self):
  self.external.json_task(json.loads(self.line), self.publicKey)
 #----------------------------------------------------------------------------------------------------

#====================================================================================================

def run():
 logfile = '/usr/local/lisk/logs.log'
 pubkey = '95bb97e05281eed1895c563cabcdb9a84cfdadbc492b03dd60b99772c8f96ba2'
 foo = log_watcher(logfile, 'json', pubkey)
 foo.log_manager()

if __name__ == '__main__':
 run()

