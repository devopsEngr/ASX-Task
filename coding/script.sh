#! /bin/bash
source ./config.conf
if jq empty $DATA_FILE; then
    echo "$DATA_FILE is valid"
else
    echo "$DATA_FILE is invalid"
    exit 1
fi

payload=$(jq 'to_entries | map(select(.value.private == false)) | from_entries' $DATA_FILE)
echo "payload_to_send: $payload"
curl -v "$BASE_URL"
response=$(curl -X POST $BASE_URL/$api_endpoint -H "Content-Type: application/json" -d "$payload")
echo "$response body: $response"
jq -r 'to_entries | map(select(.value.valid == true)) | .[].key' <<< "$response"
