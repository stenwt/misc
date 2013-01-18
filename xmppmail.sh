#!/bin/sh

SERVER=sud0.com
JID=mailnotify
JPASS=
TO=
FILE=/tmp/.xmpp$(date +%s%N)

cat - > $FILE
SUBJLINE=$(awk '/^Subject:.*$/ {for (i=2;i<NF+1;i++) {printf "%s ",$i}}' < $FILE)
FROM=$(awk '/^From:(.*)$/ {for (i=2;i<NF+1;i++) {printf "%s ",$i}}' < $FILE)
#BODY=$(grep -m 1 -A 15 "^$" $FILE)
#BODY=$(mailtextbody< $FILE)
#BODY="new mail" 
SUBJ="${SUBJLINE} from ${FROM}"
BODY=$SUBJ

rm -f $FILE

echo $BODY | sendxmpp -j $SERVER -t -u $JID -p $JPASS -s "$SUBJ" $TO 
