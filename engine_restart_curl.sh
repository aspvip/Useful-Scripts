#!/bin/bash

##Usage
if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` enginename"
  exit 0
fi

#HOME=/data01/home/s604367
ENGCTRL="/data01/cv/scripts/engineControl.sh"
ENGCTRL_ORA="/data01/cv/scripts/engineControl_Oracle.sh"
ENGHOME=/data01/cv/VEngines
REQENG=$1

###FUNCTIONS###
findeng () {
	if [[ -z $REQENG ]]; then
		echo "List of running engines"
		echo "-----------------------"
        	ps -ef|grep "Engine"|egrep -iv 'grep|awk|Factory'|sort -k8| awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); sub( /iiop:\/\/:/, ""); print $8 }'
		printf "\n"
        	read -p "Enter Engine name: " -r
        	echo
        	REQENG=$REPLY
   	fi
	ENGINE=`find $ENGHOME/*/bin -maxdepth 1 -type f -iname "Engine*\$REQENG*"| cut -d'/' -f5`
	#echo "ENGINE = $ENGINE"
	ENGEXE=`find $ENGHOME/*/bin -maxdepth 1 -type f -iname "Engine*\$REQENG*"| cut -d'/' -f7`
	#echo "ENGEXE = $ENGEXE"
	if [[ -z $ENGINE && $ENGHOME ]]; then
		printf "ERROR: ENGINE NOT FOUND\n\n"
		REQENG=""
               	findeng
	fi
	#PORT=`ps -ef|grep -i $ENGINE|egrep -iv 'grep|awk|Factory'|awk '{ sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $12 }' 2>&1`
	#if [[ -z $PORT ]]; then
        	#PORT=`find $ENGHOME/$ENGINE/bin -maxdepth 1 -type f -iname "license\ on\ port*"|cut -d' ' -f4 2>&1`
        	#PORT=`grep -w $ENGINE $HOME/scripts/engport.list|awk '{print $2}'`
                	#if [[ -z $PORT ]]; then
				#echo "ERROR: PORT NOT FOUND. PLEASE INVESTIGATE."
                        	#exit 1
                	#fi
	#fi

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
	LCENG=`echo "$ENGINE"| awk '{ print tolower($0) }'`
	curl http://localhost/$LCENG/bot.htm > /dev/null 2>&1
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
