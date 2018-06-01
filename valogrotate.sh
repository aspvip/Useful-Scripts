#!/bin/bash -xv

##Daily cron script to rotate/archive engine files
##Zips yesterday's logs for ftp rsync

#shopt -s nocaseglob nocasematch

LOGHOME=/opt/cv/logs
ENGHOME=/opt/cv/VEngines
TCHOME=/opt/cv/AppServers
YESTERDAY=`date -d 'YESTERDAY' +"%-d%-m%Y"`
YESTERDAY1=`date -d 'YESTERDAY' +"%m-%d-%Y"`
YESTERDAY2=`date -d 'YESTERDAY' +"%Y%m%d"`
YESTERDAY3=`date -d 'YESTERDAY' +"%Y-%m-%d"`
YESTERDAY4=`date -d 'YESTERDAY'  +"%m%d%Y"`

##Daily Engine and Tomcat log archive/rotation
for ENGINE in $(ps aux|grep "./Engine"|egrep -iv 'grep|awk|Factory|poc|quark'|sort -k11| awk '{ sub( /\.\/Engine/, ""); print $11 }'); do
	echo "++++ Archive/Rotation: $ENGINE ++++"
        [ -d $LOGHOME/$ENGINE ] || mkdir -p $LOGHOME/$ENGINE
        ENGLOGARCH=$LOGHOME/$ENGINE/$YESTERDAY1/VEngines
        UILOGARCH=$LOGHOME/$ENGINE/$YESTERDAY1/UILayer
        ENGLOG=$ENGHOME/$ENGINE/var/log
        mkdir -p $ENGLOGARCH $UILOGARCH
        cd $ENGLOG
        ##Compress/move yesterday's vpt
        zip $ENGLOGARCH/$YESTERDAY2.vpt.zip $YESTERDAY2.vpt
        [ -s $ENGLOGARCH/$YESTERDAY2.vpt.zip ] || ll $ENGLOGARCH | mailx -s "Missing yesterday's vpt of $ENGINE on `uname -n`" infra_usa@creativevirtual.com
        ##Copy engine logs
        for LOG in `ls *.txt *.log|egrep -v 'global_filelogger|VAEngineLogger'`; do
                if [ -s $LOG ]; then
                        cp $LOG $LOG-$YESTERDAY4
                        if [ `stat -c %s $LOG` -gt 52428800 ]; then
                                truncate -s 0 $LOG
                        fi
                mv $LOG-$YESTERDAY4 $ENGLOGARCH
                fi
        done

        ##Copy latest global/engine logger file
        for LOG in `ls -t global*.log|head -1` `ls -t VAEngine*.txt|head -1`; do
                if [ -s $LOG ]; then
                        cp $LOG $ENGLOGARCH
                fi
        done
	##Copy UI log files
        if [[ $ENGINE =~ Metro ]]; then
                find $TCHOME -type f -size +0 -iname "$ENGINE"_CVDiagnostic.log."$YESTERDAY3" -exec cp {} $UILOGARCH \;
                sleep 1
                [ -s $UILOGARCH/${ENGINE}_CVDiagnostic.log.${YESTERDAY3} ] || ll $UILOGARCH | mailx -s "Missing yesterday's $ENGINE diag log on `uname -n`" infra_usa@creativevirtual.com
        else
                find $TCHOME -type f -size +0 -iname "$ENGINE"CVDiagnostic.log."$YESTERDAY3" -exec cp {} $UILOGARCH \;
                sleep 1
                [ -s $UILOGARCH/${ENGINE}CVDiagnostic.log.$YESTERDAY3 ] || ll $UILOGARCH | mailx -s "Missing yesterday's $ENGINE diag log on `uname -n`" infra_usa@creativevirtual.com
        fi
        LCENG=`echo "$ENGINE"| awk '{ print tolower($0) }'`
        case $LCENG in
                metrolinx) LCENG=metroprodlc;;
                metrolinxvc) LCENG=metroprodvc;;
                metrolinxfrenchlc) LCENG=metroprodfrenchlc;;
                metrolinxfrenchvc) LCENG=metroprodfrenchvc;;
        esac
        echo "LCENG = $LCENG"
        for TCINST in `ls $TCHOME|grep -i $LCENG|cut -d _ -f2`; do
                cd $TCHOME/tomcat_$TCINST/logs
                for TCLOG in `find * -type f -size +0 -iname "localhost_access*" -mtime 0 -o -iname "catalina*" -mtime 0`; do
                        cp $TCLOG $UILOGARCH/$TCINST.$TCLOG
			[ -s $UILOGARCH/$TCINST.$TCLOG ] || ll $UILOGARCH | mailx -s "Missing yesterday's $ENGINE $TCLOG log on `uname -n`" infra_usa@creativevirtual.com
                done
        done
        ##Compress logs > 100MB
        for LOG in `find $LOGHOME/$ENGINE/$YESTERDAY1/* -size +100M -type f`; do
                cd `dirname $LOG`
                gzip $LOG
        done
        ##Zip yesterday's logs
        echo "++++ Zipping Logs: $ENGINE ++++"
        cd $LOGHOME/$ENGINE
        for DIR in $(find * -maxdepth 0 -type d); do
                echo "Zipping $ENGINE $DIR"
                zip -rmT $DIR.zip $DIR
                [ -f $DIR.zip ] || echo "$0 : Problem with daily log zip archive on `uname -n`. Please investigate." | mailx -s "Log Archive Failure: $ENGINE `basename $0`" infra_usa@creativevirtual.com
        done
done
