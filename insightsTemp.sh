#!/bin/bash
#insertKey='YourNRAPIKeyHere'

curl -X POST -H "Content-Type: application/json" -H "X-Insert-Key: $insertKey" https://insights-collector.newrelic.com/v1/accounts/(yourNRAccountID)/events -d \
'[
{
"eventType":"FreezerTempEvent",
"freezerID":"Basement",
"freezerTemp":"'$1'",
"ambientTemp":"'$2'",
"lastUpdateTime":"'$3'"
}
]'
