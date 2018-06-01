#!/bin/sh
# setdate - friendly front-end to the date command

HOSTNAME=`hostname`

# Date wants: [[[[[cc]yy]mm]dd]hh]mm

if [ -f /var/lock/subsys/ntpd ] ; then
        if sudo /etc/init.d/ntpd stop ; then
        echo
        else echo "Sorry, you do not have permission to stop ntp."
        exit 0
        fi
fi

echo "=== Metrolinx Hours of Operation (HOO) ==="
echo "*** (Nov-Mar) 6am - 10pm EST => 11am - 3am UTC (next day) ***"
echo "*** (Mar-Nov) 6am - 10pm EDT => 10am - 2am UTC (next day) ***"
echo "Enter values for new date:"

askvalue()
{
  # $1 = field name, $2 = default value, $3 = max value,
  # $4 = required char/digit length

  echo -n "$1 [$2] : "
  read answer
  if [ ${answer:=$2} -gt $3 ] ; then
    echo "$0: $1 $answer is invalid"; exit 0
  elif [ "$(( $(echo $answer | wc -c) - 1 ))" -lt $4 ] ; then
    echo "$0: $1 $answer is too short: please specify $4 digits"; exit 0
  fi
  eval $1=$answer
}

eval $(date "+nyear=%Y nmon=%m nday=%d nhr=%H nmin=%M")

askvalue year $nyear 3000 4
askvalue month $nmon 12 2
askvalue day $nday 31 2
echo -n "(24-hour format 00..23) "
askvalue hour $nhr 24 2
askvalue minute $nmin 59 2

newdate="$month$day$hour$minute$year"

#echo
#read -p "Slack Channel <i.e altice-ops> : " -r
#echo
#SLACK_CHANNEL=`echo $REPLY|awk '{print tolower($0)}'`
SLACK_CHANNEL="metrolinx-ops"
echo
echo -n "The date is now: "

if sudo date $newdate; then
        export SLACKCAT_WEBHOOK_URL=https://hooks.slack.com/services/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
        export SLACKCAT_USERNAME="timebot"
        export SLACKCAT_ICON_URL="https://emojipedia-us.s3.amazonaws.com/thumbs/120/google/119/mantelpiece-clock_1f570.png"
        sh -c "uname -n; env TZ=America/New_York date; date" | slackcat "#"${SLACK_CHANNEL}
else echo "Sorry, you do not have permission to change the date."
fi

exit 0
