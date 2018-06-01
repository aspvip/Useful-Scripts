#!/bin/bash

case `uname -n` in
	*ch*) HOST=vaprod1-CH;;
	*nj*) HOST=vaprod2-NJ;;
	*STAGE*) HOST=vastage1;;
	*DEV*) HOST=vadev1;;
	*) HOST=`uname -n`;;
esac

if [[ "$1" =~ [Aa][Ll][Ll] ]]; then
	for ENG in `ls /opt/cv/VEngines/|grep -i stag`; do
		 ps -AwwO lstart|grep -i $ENG|egrep -iv "grep|awk|Factory|^vi*|java|tail|$0"|sort -k10| awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $10" "$14" "$3" "$4" "$6" "$5 }' >> /tmp/getengportver.out
	cat /tmp/getengportver.out
	done
elif [ -z "$1" ]; then
	ps -AwwO lstart|grep "./Engine"|egrep -iv 'grep|awk|Factory'|sort -k10| awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $10" "$14" "$3" "$4" "$6" "$5 }' > /tmp/getengportver.out
else 
	ps -AwwO lstart|grep -i $1|egrep -iv "grep|awk|Factory|^vi*|java|tail|$0"|sort -k10| awk '{ sub( /\.\/Engine/, ""); sub( /Stage/, "Staging"); sub( /iiop:\/\/:/, "") sub( /\/hostname.*/, ""); print $10" "$14" "$3" "$4" "$6" "$5 }' > /tmp/getengportver.out
fi
#cat /tmp/getengportver.out

printf "%-100s \n" "Engine            Port    Eng Ver     UI Ver      Host          Started"
printf "%-10s  \n" "------            ----    -------     ------      ----          -------"
while read ENGINE PORT MONTH DAY YEAR TIME; do
        printf "%-18s" $ENGINE
        printf "%-8s" $PORT
	if [ -s /opt/cv/VEngines/$ENGINE/var/log/stdout.log ]; then
        	printf "%-12s" `strings /opt/cv/VEngines/$ENGINE/var/log/stdout.log|grep 'v[0-9].[0-9].*'|tail -1|awk '{print $7}'`
	else 	printf "%-12s" "N/A"; fi
	if [ -s /opt/cv/apache-tomcat*/logs/$ENGINE\CVDiagnostic.log ]; then
        	printf "%-12s" `tail -100 /opt/cv/apache-tomcat*/logs/$ENGINE\CVDiagnostic.log|grep 'v[0-9].[0-9].*'|tail -1|cut -d '|' -f2`
	else 	printf "%-12s" "N/A"; fi
        printf "%-14s" $HOST
        printf "%-3s %-1s %-4s %-10s\n" $MONTH $DAY $YEAR $TIME
done < /tmp/getengportver.out
/bin/rm /tmp/getengportver.out
