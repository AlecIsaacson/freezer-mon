#!/bin/bash

# This runs every 15 minutes and notifies us if the temperature is too high.

# Set thresholds
freezerWarningThreshold=25
freezerCriticalThreshold=30

ambientHighThreshold=80
ambientLowThreshold=50

# Who are we going to tell if there is a problem
emailRecipients="me@example.com,someoneelse@example.com"

# Where are the RRD files with our temperature data in them
freezerTempRRD=/var/lib/rpimonitor/stat/freezer_temp.rrd
ambientTempRRD=/var/lib/rpimonitor/stat/ambient_temp.rrd

# Extract the last temperature entry from the datafile.
freezerCurrentTemp=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ' ' -f 2`
ambientCurrentTemp=`rrdtool lastupdate $ambientTempRRD | grep : | cut -d ' ' -f 2`

# Cut off the decimal part.
freezerCurrentTempInt=${freezerCurrentTemp%.*}
ambientCurrentTempInt=${ambientCurrentTemp%.*}

# Sometimes we don't get updates, so check the timestamp of the entry we're using isn't too stale.
lastUpdateTime=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ':' -f 1`
currentTime=`date +%s`
timeThreshold=$(($currentTime-300))

# Log everything to syslog for future research.
logger -p local0.notice -t FREEZER-MON "Freezer temperature is $freezerCurrentTemp ($freezerCurrentTempInt)"
logger -p local0.notice -t FREEZER-MON "Ambient temperature is $ambientCurrentTemp ($ambientCurrentTempInt)"
logger -p local0.notice -t FREEZER-MON "Last temperature update time is $lastUpdateTime. Time threshold is $timeThreshold "

# Log the datapoint to NR.
insertKey='YourNRAPIKeyHere'

curl -X POST -H "Content-Type: application/json" -H "X-Insert-Key: $insertKey" https://insights-collector.newrelic.com/v1/accounts/1564921/events -d \
'[
{
"eventType":"FreezerTempEvent",
"freezerID":"Basement",
"freezerTemp":"'$freezerCurrentTemp'",
"ambientTemp":"'$ambientCurrentTemp'",
"lastUpdateTime":"'$lastUpdateTime'"
}
]'

# See if we've exceeded thresholds and tell someone about it.
if [ "$freezerCurrentTempInt" -ge "$freezerWarningThreshold" ] && [ "$freezerCurrentTempInt" -lt "$freezerCriticalThreshold"  ]
then
        echo "Freezer temperature = $freezerCurrentTempInt degrees" | mail -s "Freezer Warning" "$emailRecipients"
        logger -p local0.notice -t FREEZER-MON "Freezer warning sent to $emailRecipients"
fi

if [ "$freezerCurrentTempInt" -ge "$freezerCriticalThreshold" ]
then
        echo "Freezer temperature = $freezerCurrentTempInt degrees" | mail -s "Freezer Alarm" "$emailRecipients"
        logger -p local0.notice -t FREEZER-MON "Freezer alarm sent to $emailRecipients"
fi

if [ "$ambientCurrentTempInt" -ge "$ambientHighThreshold" ]
then
	echo "Basement ambient temperature = $ambientCurrentTempInt degrees" | mail -s "Basement Too Hot" "$emailRecipients"
	logger -p local0.notice -t FREEZER-MON "Ambient too hot alarms sent to $emailRecipients"
fi

if [ "$ambientCurrentTempInt" -le "$ambientLowThreshold" ]
then
		echo "Basement ambient temperature = $ambientCurrentTempInt degrees" | mail -s "Basement Too Cold" "$emailRecipients"
		logger -p local0.notice -t FREEZER-MON "Ambient too cold alarm sent to $emailRecipients"
fi

# See if we have stopped getting data for some reason.
if [ "$lastUpdateTime" -le "$timeThreshold" ]
then
	echo "Last temperature sample too old." | mail -s "Temperature Sensor Failure" "$emailRecipients"
	logger -p local0.notice -t FREEZER-MON "Last temperature sample too old. Update time = $lastUpdateTime. Threshold = (($currentTime-300)"
fi
