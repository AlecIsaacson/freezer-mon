#!/bin/bash

loopCount=0

while [ -z $temp ]; do
   let loopCount+=1
   rawTemp=`cat /root/$1`
   temp=`echo $rawTemp | grep -Po 't=\K(.*)$'`
   sleep 3
done

if [ $loopCount -gt 3 ]; then 
   logger -p local0.notice -t GET-TEMP "Get temp for $1 took $loopCount loops. Result was $temp. Raw result: $rawTemp"
fi

echo "`date` - $1 - $loopCount - $rawTemp" >> /var/lib/rpimonitor/stat/getTemp.out


echo "$temp"
