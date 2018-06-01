#!/bin/bash -xv

SLACK_CHANNEL="@sandra"
SLACK_TEXT=$(uname -n; env TZ=America/New_York date; date)
curl -X POST --data-urlencode "payload={\"text\": \"${SLACK_TEXT}\", \"channel\": \"${SLACK_CHANNEL}\", \"username\": \"time-bot\", \"icon_emoji\": \":mantelpiece_clock:\"}" "${SLACKCAT_WEBHOOK_URL}"
        #sh -c "uname -n; env TZ=America/New_York date; date" | slackcat ${SLACK_CHANNEL}

