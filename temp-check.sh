freezerWarningThreshold=25
freezerCriticalThreshold=30

ambientHighThreshold=80
ambientLowThreshold=50

emailRecipients="me@example.com,someoneelse@example.com"

freezerTempRRD=/var/lib/rpimonitor/stat/freezer_temp.rrd
ambientTempRRD=/var/lib/rpimonitor/stat/ambient_temp.rrd

freezerCurrentTemp=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ' ' -f 2`
ambientCurrentTemp=`rrdtool lastupdate $ambientTempRRD | grep : | cut -d ' ' -f 2`

freezerCurrentTempInt=${freezerCurrentTemp%.*}
ambientCurrentTempInt=${ambientCurrentTemp%.*}

lastUpdateTime=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ':' -f 1`
currentTime=`date +%s`
timeThreshold=$(($currentTime-300))

logger -p local0.notice -t FREEZER-MON "Freezer temperature is $freezerCurrentTemp ($freezerCurrentTempInt)"
logger -p local0.notice -t FREEZER-MON "Ambient temperature is $ambientCurrentTemp ($ambientCurrentTempInt)"
logger -p local0.notice -t FREEZER-MON "Last temperature update time is $lastUpdateTime. Time threshold is $timeThreshold "

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

if [ "$lastUpdateTime" -le "$timeThreshold" ]
then
	echo "Last temperature sample too old." | mail -s "Temperature Sensor Failure" "$emailRecipients"
	logger -p local0.notice -t FREEZER-MON "Last temperature sample too old. Update time = $lastUpdateTime. Threshold = (($currentTime-300)"
fi
