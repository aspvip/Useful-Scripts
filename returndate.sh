#!/bin/sh
# returndate - QA to sync time using ntp

HOSTNAME=`hostname`

if [ -f /var/lock/subsys/ntpd ] ; then
    echo "Stopping ntp daemon"
    if sudo /etc/init.d/ntpd stop ; then
    echo
    else echo "Sorry, you do not have permission to sync date."; exit 0
    fi
fi

#read -p "Slack Channel <i.e altice-ops> : " -r
#echo
#SLACK_CHANNEL=`echo $REPLY|awk '{print tolower($0)}'`
SLACK_CHANNEL="metrolinx-ops"
#echo
echo -n "The date is now: "

echo "Syncing date and time..."
if sudo /usr/sbin/ntpdate 0.centos.pool.ntp.org; then
        sudo /etc/init.d/ntpd start
        echo
        echo "The date is now: `date`"
        export SLACKCAT_WEBHOOK_URL=https://hooks.slack.com/services/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
        export SLACKCAT_USERNAME="timebot"
        export SLACKCAT_ICON_URL="https://emojipedia-us.s3.amazonaws.com/thumbs/120/google/119/mantelpiece-clock_1f570.png"
        sh -c "uname -n; env TZ=America/New_York date; date" | slackcat "#"${SLACK_CHANNEL}
fi
