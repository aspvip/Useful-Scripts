#!/bin/bash

##Usage
if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` enginename"
  exit 0
fi

ENGCTRL="/data01/cv/scripts/engineControl.sh"
ENGCTRL_ORA="/data01/cv/scripts/engineControl_Oracle.sh"
ENGHOME=/data01/cv/VEngines
REQENG=$1

###FUNCTIONS###
findeng () {
	if [[ -z $REQENG ]]; then
		echo "List of running engines"
		echo "-----------------------"
        	ps -ef|grep "Engine"|egrep -iv 'grep|awk|Factory'|sort -k8| awk '{ sub( /\.\/Engine/, ""); sub( /iiop:\/\/:/, ""); sub( /\_/, ""); print $8 }'
        	#ps -ef|grep "Engine"|egrep -iv 'grep|awk|Factory'|sort -k8| awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); sub( /iiop:\/\/:/, ""); sub( /\_/, ""); print $8 }'
		printf "\n"
        	read -p "Enter Engine name: " -r
        	echo
        	REQENG=$REPLY
   	fi
	if [[ $REQENG =~ KB*Arch* ]]; then
		ENGINE=KB_Arch_Stage
		ENGEXE=EngineKBArchStage
	else
		ENGINE=`find $ENGHOME/*/bin -maxdepth 1 -type f -iname "Engine*\$REQENG*"| cut -d'/' -f5`
		ENGEXE=`find $ENGHOME/*/bin -maxdepth 1 -type f -iname "Engine*\$REQENG*"| cut -d'/' -f7`
	fi
	echo "ENGINE = $ENGINE"
	echo "ENGEXE = $ENGEXE"
	if [[ -z $ENGINE && $ENGHOME ]]; then
		printf "ERROR: ENGINE NOT FOUND\n\n"
		REQENG=""
               	findeng
	fi
	PORT=`ps -ef|grep -i $ENGINE|egrep -iv 'grep|awk|Factory'|awk '{ sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $12 }' 2>&1`
	if [[ -z $PORT ]]; then
       		PORT=`grep $ENGEXE /data01/cv/EngineFactory/bin/*.sh|awk '{print $4}'`
                	if [[ -z $PORT ]]; then
				echo "ERROR: PORT NOT FOUND. PLEASE INVESTIGATE."
                        	exit 1
                	fi
	fi

	#echo $ENGINE $ENGEXE $PORT
	confirmeng
}

confirmeng () {
	read -p "Restart '$ENGINE'? [y|n] " -n 1 -r
	echo
	case $REPLY in
		y|Y) restarteng ;;
		*)	REQENG=""; findeng ;;
	esac
}

restarteng () {
	printf "\nStopping.....$ENGINE\n"
	sudo -u cvadmin $ENGCTRL stop $ENGEXE
	sleep 15
	if [[ $ENGINE == VZWStaging ]]; then
        	printf "\nStarting.....$ENGINE\n"
        	sudo -u cvadmin $ENGCTRL_ORA start $ENGHOME/$ENGINE/bin/$ENGEXE $PORT
	else
        	printf "\nStarting.....$ENGINE\n"
        	sudo -u cvadmin $ENGCTRL start $ENGHOME/$ENGINE/bin/$ENGEXE $PORT
	fi

	##Confirm engine is back online - Look for "Ready to answer requests"
	sleep 20
	printf "\nTailing log.....$ENGINE\n"
	/usr/bin/iconv -f utf-16 -t ascii//translit $ENGHOME/$ENGINE/var/log/error.txt|tail
	if /usr/bin/iconv -f utf-16 -t ascii//translit $ENGHOME/$ENGINE/var/log/error.txt|tail|grep "Ready to answer requests"; then
		echo; /usr/local/bin/getengportver.sh $ENGEXE
	else printf "\n**Engine $ENGINE failed to start. Please investigate**"
	fi
}

###MAIN###
findeng
