#!/bin/bash

ENGINE=$1
HOST=`uname -n`
IP=`ip addr show dev eth0|grep inet|head -1|awk '{ sub( /\/.*/, ""); print $2 }'`
ENGPATH=`ls /data01/cv/VEngines/*\$ENGINE*/bin/Engin*`
RELEASE=`strings /data01/cv/VEngines/$ENGINE*/var/log/stdout.log|grep 'v[0-9].[0-9].*'|tail -1|awk '{ sub( /,/, "") sub( /v/, ""); print $1}'`
PORT=`grep -ir $ENGINE /opt/cv/EngineFactory/bin/*.sh| cut -d' ' -f4`
MAC=`ip addr show dev eth0 | grep "link/ether" | /bin/awk '{print $2}'`

echo "Client: $1"
echo "Hostname: $HOST"
echo "IP: $IP "
echo "Path: $ENGPATH"
echo "Release: $RELEASE"
echo "Port: $PORT"
echo "MAC: $MAC"
if [ -s /home/cvadmin/VEngine.hdf ]; then
        echo "HDF file location: /home/cvadmin/VEngine.hdf"
else
        echo "Generating HDF file...."
        export LD_LIBRARY_PATH=/opt/cv/EngineFactory/bin
        /data01/software*/Dependencies/HDFGenerator
	mv ./VEngine.hdf /home/cvadmin
	chown cvadmin:users /home/cvadmin/VEngine.hdf
        echo "HDF file location: /home/cvadmin/VEngine.hdf"
fi
