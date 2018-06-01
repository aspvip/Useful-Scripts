#!/bin/bash

NODE=`uname -n`
EMAIL_FROM="haproxyalert@$NODE"
EMAIL_TO="infra_usa@creativevirtual.com"
HADOWN=`echo 'show stat' | nc -U /var/run/haproxy/haproxy.sock|sed 1,1d|grep -i down|awk -F, '{print $1" "$2" "$18" "$57}'`
HAUP=`echo 'show stat' | nc -U /var/run/haproxy/haproxy.sock|sed 1,1d|grep -i up|awk -F, '{print $1" "$2" "$18" "$57}'`

if [ -n "$HADOWN" ]; then
        touch /tmp/.hadown
        ( uname -n; echo "$HADOWN" ) | mailx -Es "HAProxy: DOWN status on $NODE" -r $EMAIL_FROM $EMAIL_TO
        #( uname -n; echo "$HADOWN" ) | mailx -Es "HAProxy: DOWN status on $NODE" sandra.fredenburgh@creativevirtual.com
        exit 0
elif [[ -z "$HADOWN" ]] && [[ `find /tmp -name .hadown` ]]; then
        rm /tmp/.hadown
        ( uname -n; echo "$HAUP" ) | mailx -Es "HAProxy: UP status on $NODE" -r $EMAIL_FROM $EMAIL_TO
        #( uname -n; echo "$HAUP" ) | mailx -Es "HAProxy: UP status on $NODE" sandra.fredenburgh@creativevirtual.com
fi

