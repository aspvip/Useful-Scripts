#!/bin/bash

##Usage
if [ "$1" == "-h" ] || [ `whoami` != "cvadmin" ] || [ $# -eq 0 ]; then
  echo "Usage: `basename $0` <enginename>"
  echo "**Run as user cvadmin**"
  exit 0
fi

#----------------------------------------------#
#~  <============== NOTES ===============>
#~  Add  new engines under "MAIN" section ~
#~  Do not edit VARIABLES or FUNCTION sections ~
#----------------------------------------------#

#----------------------------------------------#
################# VARIABLES ####################
#----------------------------------------------#
case `uname -n` in
        *"DEV"*)        ENV=dev;;
        *"STAGE"*)      ENV=stage;;
        *)              ENV=prod;;
esac
ENGINE=`echo "$1"| awk '{ print tolower($0) }'`
SITE=$(exec uname -n|cut -c 1-3|awk '{ print tolower ($0) }')
TODAY=`date +"%Y%m%d"`
TIMETODAY=`date +"%H-%M"`
UIARCHDIR=/data01/software/ui-updates/$ENGINE/$TODAY
#Determine package name
if [ "$ENGINE" == "presto" ] && [ "$SITE" == "ca3" ] && [ "$ENV" == "prod" ]; then
        PACKAGE=release_"$ENGINE"card_prestolc01.zip
elif [ "$ENGINE" == "presto" ] && [ "$SITE" == "ca1" ]; then
        PACKAGE=release_"$ENGINE"card_prestolc02.zip
elif [ "$ENGINE" == "presto" ] && [ "$ENV" == "dev" ]; then
        PACKAGE=release_"$ENGINE"carddev.zip
elif [ "$ENGINE" == "presto" ] && [ "$ENV" == "stage" ]; then
        PACKAGE=release_"$ENGINE"cardstage2.zip
elif [ "$ENV" == "dev" ]; then
        PACKAGE=release_cv"$ENGINE"dev1.zip
elif [ "$ENV" == "stage" ]; then
        PACKAGE=release_"$ENGINE"stage.zip
else PACKAGE=release_"$ENGINE".zip
fi
UIDIR=/opt/cv/UIServers
UI="$ENGINE"_va_ui
UIVERSION=$(grep -i versionnumber $UIDIR/$UI/cv_va_lib/cv-va.js|awk -F\" '{ print $2 }')
#Determine proxy and json file names
case "$ENV" in
        dev|stage)      UIAPP="$ENGINE""$ENV"-va-proxy
                        UIJSON="$ENGINE""$ENV"_ui.json
                        ;;
        *)              UIAPP="$ENGINE"-va-proxy
                        UIJSON="$ENGINE"_ui.json
                        ;;
esac
UIZIP=`echo $PACKAGE| cut -d. -f1`
export SLACKCAT_WEBHOOK_URL="https://hooks.slack.com/services/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"
#export SLACKCAT_USERNAME="abraham-linksys"
#export SLACKCAT_ICON_URL="https://cdn0.iconfinder.com/data/icons/flatico/512/monitor_code__editor-256.png"

#----------------------------------------------#
################# FUNCTION ####################
#----------------------------------------------#
deploy-ui () {
        if [ -s $UIDIR/$UIJSON ]; then
                echo "Deploying $PACKAGE package"
                if [ -d $UIARCHDIR ];then
                        echo "Directory exists, renaming.."
                        mv $UIARCHDIR $UIARCHDIR."$TIMETODAY"
                fi
                mkdir -p $UIARCHDIR/backup
                cp -ap /home/cvadmin/tmp/$PACKAGE $UIARCHDIR
                cd $UIARCHDIR
                unzip -q $PACKAGE
                if [ -d $UIARCHDIR/release ];then
                        rsync -a $UIDIR/$UI backup/
                        pm2 stop $UIAPP
                        pm2 delete $UIAPP
                        rsync -av --delete release/ $UIDIR/$UI/
                        sed -i -e 's/process.env.PORT || '\''65[0-9][0-9]'\'';/process.env.PORT || '\'$UIPORT\'';/' $UIDIR/$UI/va-proxy.js
                        cd $UIDIR/$UI
                        npm install
                        pm2 start $UIDIR/$UIJSON
                        sleep 10
                        pm2 status
                        pm2 save
                        #Remote FTP cleanup
                        ssh sftp.creativevirtual15.com "mkdir -p ui-updates/$ENGINE/$ENV/archive; cp ui-updates/$ENGINE/$ENV/$PACKAGE ui-updates/$ENGINE/$ENV/archive/"$UIZIP"_"$TODAY".$TIMETODAY.zip; \
                        find ui-updates/$ENGINE/$ENV/archive/ -type f | sort -nr | tail -n +7 | xargs rm -rf"
                        #Local cleanup
                        find /data01/software/ui-updates/$ENGINE/ -maxdepth 1 -type d | sort -nr | tail -n +7 |xargs rm -rf
                else
                        echo "ERROR: $PACKAGE not found, aborting"
                        rm -rf /home/cvadmin/tmp/*
                        exit 1
                fi
        else
                echo "ERROR: missing json file"
                rm -rf /home/cvadmin/tmp/*
                exit 1
        fi
}

#----------------------------------------------#
################# MAIN ######################## ** Edit Engine + UIPort variables below beginning at line 100 **
#----------------------------------------------#
mkdir -p /home/cvadmin/tmp
scp cvadmin@sftp.creativevirtual15.com:/home/cvadmin/ui-updates/$ENGINE/$ENV/$PACKAGE /home/cvadmin/tmp/
sleep 20
if [ -s /home/cvadmin/tmp/$PACKAGE ]; then
        case "$ENGINE" in
                presto) UIPORT=6550;;
                cox)    UIPORT=6550;;
                nyt)    UIPORT=6551;;
                asus)   UIPORT=6552;;
                altice) UIPORT=6553;;
                ihg) 	UIPORT=6554;;
                *)      echo "ERROR: No matches found to deploy, aborting"; exit 1;;
        esac
        deploy-ui
        if [ "$ENGINE" == "presto" ]; then
		echo "UI pkg deployed: $ENGINE $ENV on `hostname` $UIVERSION"| slackcat '#metrolinx-ops'
                echo "UI pkg deployed: $ENGINE $ENV on `hostname` $UIVERSION"| slackcat '#ui-deployment'
        else
                echo "UI pkg deployed: $ENGINE $ENV on `hostname` $UIVERSION"| slackcat '#'${ENGINE}-ops
                echo "UI pkg deployed: $ENGINE $ENV on `hostname` $UIVERSION"| slackcat '#ui-deployment'
        fi
else
        echo "ERROR: No files copied, aborting"
        rm -rf /home/cvadmin/tmp/*
        exit 1
fi

#cleaning up ftp
if [ $ENV != "prod" ]; then
        ssh sftp.creativevirtual15.com rm ui-updates/$ENGINE/$ENV/release_*.zip
fi
