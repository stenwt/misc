#!/usr/bin/env python

APILOGIN = 
APIKEY = 
HOSTNAME = 
DOMAIN = 
TYPE = 'A'
TTL = '300'

import socket
#newip = socket.gethostbyname(socket.gethostname())
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)                                                        
s.connect(('google.com', 0))
newip = s.getsockname()[0]
s.close()


RECORD = HOSTNAME + '.' + DOMAIN

from pynfsn import pynfsn
import syslog

oldip = None
api = pynfsn.NFSN(APILOGIN, APIKEY)
dom = api.dns(DOMAIN)
for x in dom.listRRs():
  if (x['name'] == HOSTNAME):
    oldip = x['data']

if (oldip != None):
  if (oldip != newip):
    try:
      dom.removeRR(HOSTNAME, TYPE, oldip)
      dom.addRR(HOSTNAME, TYPE, newip, TTL)
      dom.updateSerial()
      syslog.syslog(HOSTNAME + " now set to " + newip)
    except Exception, e: 
      syslog.syslog(syslog.LOG_ERR, "Error updating record : %s" % (e))
  else:
    syslog.syslog(syslog.LOG_ERR, "IP stayed the same, nothing to do.")
else:
  syslog.syslog(syslog.LOG_ERR, HOSTNAME + " not found!")

