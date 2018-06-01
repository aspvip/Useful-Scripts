#!/bin/bash -xv

EMAIL_TO="infra_usa@creativevirtual.com"
NODE="vastage1"
EMAIL_FROM="$NODE@`uname -n`"
SLACK_CHANNEL="#infra-alerts"
export SLACKCAT_WEBHOOK_URL=https://hooks.slack.com/services/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

echo "Stopping tomcat..."
#service tomcat.auth stop
#sudo /etc/init.d/tomcat.auth stop
/usr/local/bin/authbind --deep /opt/cv/apache-tomcat-7.0.42/bin/shutdown.sh
echo "Killing engines..."
kill `ps ax |grep -v kill| awk 'BEGIN{IGNORECASE=1}/Stag/{print $1}'`
sleep 60
echo "Starting tomcat..."
#service tomcat.auth start
#sudo /etc/init.d/tomcat.auth start
/usr/local/bin/authbind --deep /opt/cv/apache-tomcat-7.0.42/bin/startup.sh
sleep 120
grep -B1 'INFO: Server startup in' /data01/cv/apache-tomcat-7.0.42/logs/catalina.out | tail -2 | mailx -Es "Tomcat reset on vastage1" -r $EMAIL_FROM $EMAIL_TO
printf "Tomcat reset on `uname -n`\n`grep -B1 'INFO: Server startup in' /data01/cv/apache-tomcat-7.0.42/logs/catalina.out|tail -2`" |slackcat $SLACK_CHANNEL
#curl -X POST --data-urlencode "payload={\"text\": \"Tomcat reset on vastage1\", \"channel\": \"${SLACK_CHANNEL}\", \"username\": \"monkey-bot\", \"icon_emoji\": \":monkey_face:\"}" "${SLACKCAT_WEBHOOK_URL}"
