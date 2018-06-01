#!/bin/bash

#Emails yesterday's global filelogger

EMAIL_TO="infra_usa@creativevirtual.com, calvin.costa@creativevirtual.com, william.hollis@creativevirtual.com"
#EMAIL_TO="sandra.fredenburgh@creativevirtual.com"
NODE=`hostname|cut -b1-3,7-15`
EMAIL_FROM="$NODE@`hostname`"
YEST=`date -d yesterday +"%Y-%m-%d"`
find /opt/cv/V*Engines/ -name "global_filelogger*" -mtime 0 | egrep -iv '(Stag|Agent|POC)' | \
while read GLOBLOG; do
	echo "FILE = $GLOBLOG"
	ENG=`dirname $GLOBLOG|cut -d '/' -f5`
	echo "ENGINE = $ENG"
	#sed -n '/'$YEST'/,$p' $GLOBLOG| awk -F':' '{OFS = FS} $3 ~ /'ERROR'/ || /'WARNING'/ { print }' | \
	sed -n '/'$YEST'/,$p' $GLOBLOG| awk -F':' '{OFS = FS} $3 !~ /'INFO'/ { print }' | \
	mailx -Es "GLOBAL LOG DIGEST: $ENG" -r $EMAIL_FROM $EMAIL_TO
done
