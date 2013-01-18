#!/usr/bin/env python
import email, sys, re, PyRSS2Gen, feedparser, datetime

ME="someone@somewhere.com"
FEEDTITLE="shared items"
FEEDFILE="/var/www/rss/share.rss"
FEEDSELF="http://somewhere.com/rss/share.rss"
FEEDDESC="stuff on the web I thought was cool"
FEEDITEMCT=20
URLMATCH='URL:.*?<a href="(.*?)">.*?</a>'

m = email.message_from_string(sys.stdin.read())
#m.get('From') == ME or exit
newtitle = re.sub(r'FW[D][:]', '', m.get('Subject'), re.I)
newdate=datetime.datetime.utcnow()
newdate = m.get('Date')

newurl = ""
allurls = re.findall(URLMATCH, m.get_payload(decode=True))
newurl = allurls[0]

if newurl and newtitle: 
  allitems = [
    PyRSS2Gen.RSSItem(
      title = newtitle,
      link = newurl,
      guid = PyRSS2Gen.Guid(newurl),
      pubDate = newdate
    )
  ]
  
  feedin=feedparser.parse(FEEDFILE)
  ct = 1
  for entry in feedin.entries:
    allitems.append (
    PyRSS2Gen.RSSItem(
      title = entry.title,
      link = entry.link,
      guid = PyRSS2Gen.Guid(entry.link),
      pubDate = entry.updated
    ))
    ct += 1
    if ct >= FEEDITEMCT:
      break

  feedout = PyRSS2Gen.RSS2(
    title = FEEDTITLE,
    link = FEEDSELF,
    description = FEEDDESC,
    lastBuildDate = datetime.datetime.utcnow(),
    items = allitems
  )

  feedout.write_xml(open(FEEDFILE, "w"))
