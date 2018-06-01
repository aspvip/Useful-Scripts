#!/bin/bash

ENGALERT=/var/log/eng_alert
EMAIL_TO="infra_usa@creativevirtual.com, calvin.costa@creativevirtual.com"
#EMAIL_TO="sandra.fredenburgh@creativevirtual.com"
NODE="vastage1"
EMAIL_FROM="$NODE@`uname -n`"

##Get live engine list
STAGEENG=`ps -ef|grep -i Engine|egrep -iv 'grep|awk|Factory'|awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); print $8 }'`

##Establish error search list
INCLUDE="error|exception|fatal"
EXCLUDE="debug"
TCERROR="exception|corba.*|severe"
SYSERROR="(segfault|out of memory)"

##List of Logs to check
ERRLOG=error.txt
GLOBLOG="global_filelogger*"
TCLOG=/data01/cv/apache-tomcat*/logs/catalina.out
SYSLOG=/var/log/messages

##Engine error search loop script
for ENGINE in $STAGEENG
do
        if [ ! -d $ENGALERT/$ENGINE ]; then
                mkdir -p $ENGALERT/$ENGINE
                touch $ENGALERT/$ENGINE/$ERRLOG.old
                touch $ENGALERT/$ENGINE/$GLOBLOG.old
        elif test "`find /data01/cv/VEngines/$ENGINE/var/log/$ERRLOG -mmin -5`"; then
                /usr/bin/iconv -f utf-16 -t ascii//translit /data01/cv/VEngines/$ENGINE/var/log/$ERRLOG|egrep -i $INCLUDE > $ENGALERT/$ENGINE/$ERRLOG
                if [ -s $ENGALERT/$ENGINE/$ERRLOG ] && ! diff -q $ENGALERT/$ENGINE/$ERRLOG.old $ENGALERT/$ENGINE/$ERRLOG; then
                        /usr/bin/diff $ENGALERT/$ENGINE/$ERRLOG.old $ENGALERT/$ENGINE/$ERRLOG | sed 1d | mailx -s "ENGINE LOG ERROR ALERT: $ENGINE" -
r $EMAIL_FROM $EMAIL_TO
                        mv $ENGALERT/$ENGINE/$ERRLOG $ENGALERT/$ENGINE/$ERRLOG.old
                fi
        #elif test "`find /data01/cv/VEngines/$ENGINE/var/log/$GLOBLOG -mmin -5`"; then
                #egrep -i $INCLUDE /data01/cv/VEngines/$ENGINE/var/log/$GLOBLOG > $ENGALERT/$ENGINE/$GLOBLOG
                #egrep -i $INCLUDE /data01/cv/VEngines/$ENGINE/var/log/$GLOBLOG | egrep -iv $EXCLUDE > $ENGALERT/$ENGINE/$GLOBLOG

                #if [ -s $ENGALERT/$ENGINE/$GLOBLOG ] && ! diff -q $ENGALERT/$ENGINE/$GLOBLOG.old $ENGALERT/$ENGINE/$GLOBLOG; then
                #        /usr/bin/diff $ENGALERT/$ENGINE/$GLOBLOG.old $ENGALERT/$ENGINE/$GLOBLOG | sed 1d | mailx -s "GLOBAL LOG ERROR ALERT: $ENGINE" -r $EMAIL_FROM $EMAIL_TO
                #        mv $ENGALERT/$ENGINE/$GLOBLOG $ENGALERT/$ENGINE/$GLOBLOG.old
                #fi
        fi
done

##Search catalina.out for errors
if [ ! -f $ENGALERT/catalina.old ]; then
        touch $ENGALERT/catalina.old
elif test "`find $TCLOG -mmin -5`"; then
        egrep -B5 -A5 -i $TCERROR $TCLOG > $ENGALERT/catalina.out
        if [ -s $ENGALERT/catalina.out ] && ! diff -q /$ENGALERT/catalina.old $ENGALERT/catalina.out; then
                /usr/bin/diff /$ENGALERT/catalina.old $ENGALERT/catalina.out | sed 1d | mailx -s "TOMCAT ERROR ALERT: $NODE" -r $EMAIL_FROM $EMAIL_TO
                mv $ENGALERT/catalina.out $ENGALERT/catalina.old
        fi
fi

##Search syslog for errors
if [ ! -f $ENGALERT/messages.old ]; then
        touch $ENGALERT/messages.old
elif test "`find $SYSLOG -mmin -5`"; then
        egrep -i "$SYSERROR" $SYSLOG > $ENGALERT/messages
        if [ -s $ENGALERT/messages ] && ! diff -q /$ENGALERT/messages.old $ENGALERT/messages; then
                /usr/bin/diff /$ENGALERT/messages.old $ENGALERT/messages | grep ">" | mailx -s "SYSLOG ALERT: $NODE" -r $EMAIL_FROM $EMAIL_TO
                #/usr/bin/diff /$ENGALERT/messages.old $ENGALERT/messages | sed 1d | mailx -s "SYSLOG ALERT: $NODE" -r $EMAIL_FROM $EMAIL_TO
                mv $ENGALERT/messages $ENGALERT/messages.old
        fi
fi
