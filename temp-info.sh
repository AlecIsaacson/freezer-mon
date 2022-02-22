#!/bin/bash

# This runs each night as a heartbeat just so I know the thing is still working.

emailRecipients="me@example.com"

# The location of the RRD files with the temperature data points.
freezerTempRRD=/var/lib/rpimonitor/stat/freezer_temp.rrd
ambientTempRRD=/var/lib/rpimonitor/stat/ambient_temp.rrd

# Get the max freezer and ambient temperature from the last 24 hour time period.
freezerMaxTemp=`rrdtool graph x -s -24h -e NOW DEF:ds0=$freezerTempRRD:freezer_temp:AVERAGE VDEF:ds0max=ds0,MAXIMUM PRINT:ds0max:%lf | tail -1`
ambientMaxTemp=`rrdtool graph x -s -24h -e NOW DEF:ds0=$ambientTempRRD:ambient_temp:AVERAGE VDEF:ds0max=ds0,MAXIMUM PRINT:ds0max:%lf | tail -1`

# Make sure we're getting regular updates.
lastUpdateTime=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ':' -f 1`
currentTime=`date +%s`
timeThreshold=$(($currentTime-300))

# Log the data in syslog for future research.
logger -p local0.notice -t FREEZER-INFO "Freezer max temperature is $freezerMaxTemp"
logger -p local0.notice -t FREEZER-INFO "Ambient max temperature is $ambientMaxTemp"
logger -p local0.notice -t FREEZER-INFO "Last temperature update time is $lastUpdateTime. Time threshold is $timeThreshold "

# Send the text message.
echo -e "Date: `date`\nFreezer max temp: $freezerMaxTemp\nAmbient max temp: $ambientMaxTemp" | mail -s "Daily Freezer Report" "$emailRecipients"
