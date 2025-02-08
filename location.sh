#!/bin/bash

# Default values
API_URL="http://192.168.0.109:3000/location"
DEVICE_ID="esp32-12376"
LOG_FILE="$HOME/location_log.txt"
INTERVAL=2  # Default interval in seconds

# Function to display usage information
usage() {
    echo "Usage: $0 [-u API_URL] [-d DEVICE_ID] [-i INTERVAL]"
    exit 1
}

# Parse command-line arguments
while getopts "u:d:i:" opt; do
    case $opt in
        u) API_URL="$OPTARG" ;;
        d) DEVICE_ID="$OPTARG" ;;
        i) INTERVAL="$OPTARG" ;;
        *) usage ;;
    esac
done

echo "Using API URL: $API_URL"
echo "Device ID: $DEVICE_ID"
echo "Update interval: $INTERVAL seconds"
echo "Logging to: $LOG_FILE"

while true; do
    # Get current location
    location=$(termux-location -p network)

    if [ $? -eq 0 ]; then
        lat=$(echo "$location" | jq '.latitude')
        lon=$(echo "$location" | jq '.longitude')

        json_payload="{\"device_id\": \"$DEVICE_ID\", \"latitude\": $lat, \"longitude\": $lon}"

        echo "Sending location data: $json_payload"

        response=$(curl -s -X POST "$API_URL" \
            -H "Content-Type: application/json" \
            -d "$json_payload")

        if echo "$response" | grep -q '"status": "success"'; then
            echo "$(date): Sent location $lat, $lon" >> "$LOG_FILE"
        else
            echo "$(date): Failed to send location data" >> "$LOG_FILE"
        fi
    else
        echo "$(date): Failed to retrieve location" >> "$LOG_FILE"
    fi

    sleep "$INTERVAL"
done

