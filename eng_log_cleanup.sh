#!/bin/bash

ENGDIR=/opt/cv/VEngines
LOGDIR=var/log
APPDIR=/opt/cv/AppServers

#Remove vpt files
if [[ (-n $(find $ENGDIR/*/$LOGDIR -name "*.vpt" -mtime +30)) ]]; then
        echo "++++ Removing VPT files +30 days ++++"
        find $ENGDIR/*/$LOGDIR -name "*.vpt" -mtime +30|xargs rm -rvf
fi

#Remove all except 2 most recent files: global_filelogger & VAEngineLogger
for ENGINE in $(find ${ENGDIR} -maxdepth 1 -mindepth 1 -type d|sort|awk -F/ '{ print $5 }'); do
        for LOG in global_filelogger*.log VAEngineLogger*; do
                if [ `ls $ENGDIR/$ENGINE/$LOGDIR/$LOG 2>/dev/null | wc -l` -gt 2 ]; then
                        echo "++++ Removing Engine Logs: $ENGINE $LOG ++++"
                        ls -t $ENGDIR/$ENGINE/$LOGDIR/$LOG|sed 1,2d|xargs rm -rvf
                fi
        done
done

#Remove engine core dumps
echo "++++ Removing core dump files +30 days +++"
find $ENGDIR/*/bin/ /opt/cv/EngineFactory/bin -name "core.*" -ctime +30|xargs rm -rvf

#Remove engine ftp files
echo "++++ Removing engine ftp files +30 days ++++"
find $ENGDIR/*/VAEngineFTPFiles -type f -mtime +30|xargs rm -rf

#Remove tomcat logs
echo "++++ Removing tomcat logs ++++"
find $APPDIR/tomcat_*/logs -type f -mtime +30|xargs rm -rvf
find $APPDIR -iname "*CVDiagnostic*.log.*" -type f -ctime +7|xargs rm -rvf

#Remove engine log zip files
echo "++++ Removing CV Engine zip files +30 days ++++"
find /opt/cv/logs/ -type f -name "*.zip" -ctime +30|xargs rm -rvf
