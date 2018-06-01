#!/bin/bash

##Usage
if [ "$1" == "-h" ] || [ $# -eq 0 ] || [ `whoami` != "cvadmin" ]; then
  echo "Usage: `basename $0` enginename **Run as user cvadmin**"
  echo "Assumes new license is in engine bin dir named $engine.License.lic"
  echo "If engine is not running, queries ~/scripts/engport.list for port"
  exit 0
fi

HOME=/data01/home/cvadmin
ENGCTRL=$HOME"/cv/scripts/engineControl.sh"
ENGCTRL_ORA=$HOME"/cv/scripts/engineControl_Oracle.sh"
ENGHOME=$HOME"/cv/VEngines"

##Determine Engine, Port and Engine Executable
ENGINE=$1

if [[ $ENGINE == TWCStaging ]]; then
        ENGEXE=EngineTWCStaging
else
        ENGEXE=$(echo "Engine"$ENGINE | sed 's/Staging/Stage/g')
fi

PORT=`ps -ef|grep -w $ENGEXE|egrep -iv 'grep|awk|Factory'|awk '{ sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $12 }'`

if [[ -z $PORT ]]; then
        PORT=`grep -w $ENGINE $HOME/scripts/engport.list|awk '{print $2}'`
                if [[ -z $PORT ]]; then
			echo "ERROR: ENGINE NOT FOUND. PLEASE INVESTIGATE."
                        exit 1
                fi
fi

#echo $ENGINE $ENGEXE $PORT

##Stop Eng, Archive old license, Apply new license, Start Eng
$ENGCTRL stop $ENGEXE
sleep 15

if [ -s $ENGHOME/$ENGINE/bin/$ENGINE.License.lic ]; then
        echo "[`date '+%F %T'`] Deploying new license"
        cd $ENGHOME/$ENGINE/bin
        [ -d archive ] || mkdir archive
        mv License.lic License.lic-`date +"%Y%m%d"`
        mv License* archive
        mv $ENGINE.License.lic License.lic
else
        echo "ERROR: $ENGINE.License.lic MISSING. Please copy the license to engine bin dir."
        exit 1
fi

if [[ $ENGINE == VZWStaging ]]; then
        $ENGCTRL_ORA start $ENGEXE $PORT
else
        $ENGCTRL start $ENGEXE $PORT
fi

##Confirm engine is back online - Look for "Ready to answer requests"
sleep 20
/usr/bin/iconv -f utf-16 -t ascii//translit $ENGHOME/$ENGINE/var/log/error.txt|tail
