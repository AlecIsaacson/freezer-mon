#!/bin/bash

emailRecipients="me@example.com"

freezerTempRRD=/var/lib/rpimonitor/stat/freezer_temp.rrd
ambientTempRRD=/var/lib/rpimonitor/stat/ambient_temp.rrd

freezerMaxTemp=`rrdtool graph x -s -24h -e NOW DEF:ds0=$freezerTempRRD:freezer_temp:AVERAGE VDEF:ds0max=ds0,MAXIMUM PRINT:ds0max:%lf | tail -1`
ambientMaxTemp=`rrdtool graph x -s -24h -e NOW DEF:ds0=$ambientTempRRD:ambient_temp:AVERAGE VDEF:ds0max=ds0,MAXIMUM PRINT:ds0max:%lf | tail -1`

lastUpdateTime=`rrdtool lastupdate $freezerTempRRD | grep : | cut -d ':' -f 1`
currentTime=`date +%s`
timeThreshold=$(($currentTime-300))

logger -p local0.notice -t FREEZER-INFO "Freezer max temperature is $freezerMaxTemp"
logger -p local0.notice -t FREEZER-INFO "Ambient max temperature is $ambientMaxTemp"
logger -p local0.notice -t FREEZER-INFO "Last temperature update time is $lastUpdateTime. Time threshold is $timeThreshold "

echo -e "Date: `date`\nFreezer max temp: $freezerMaxTemp\nAmbient max temp: $ambientMaxTemp" | mail -s "Daily Freezer Report" "$emailRecipients"
