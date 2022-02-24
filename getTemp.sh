#!/bin/bash

loopCount=0

while [ -z $temp ]; do
   let loopCount+=1
   temp=`cat /root/$1 | grep -Po 't=\K(.*)$'`
   sleep 3
done

if [ $loopCount -gt 3 ]; then 
   logger -p local0.notice -t GET-TEMP "Get temp for $1 took $loopCount loops. Result was $temp"
fi

echo "$temp"
