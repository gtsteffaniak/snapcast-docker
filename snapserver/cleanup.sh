#!/bin/sh
server=gworker
while true; do
    details=$(curl -s -X POST -H 'Content-Type: application/json' -d '{"id": 1,"jsonrpc":"2.0","method":"Server.GetStatus"}' "http://"$server":1780/jsonrpc")
    clientlist=$(echo $details | jq '.result.server.groups[] .clients[]')
    disconnected_ids=$(echo $clientlist | jq 'select(.connected==false)' | jq .id)
    if [ ! -z "$disconnected_ids" ]; then
        sleep 60
        disconnected_ids_recheck=$(echo $clientlist | jq 'select(.connected==false)' | jq .id)
        if [ "$disconnected_ids" == "$disconnected_ids_recheck" ]; then
            for id in $disconnected_ids; do
                echo disconnecting $id
                curl -s -X POST -H 'Content-Type: application/json' -d '{"id":2,"jsonrpc":"2.0","method":"Server.DeleteClient","params":{"id":'$id'}}' "http://gworker:1780/jsonrpc" >/dev/null 2>&1
            done
        fi
    fi
    sleep 60
done
