# LocationScript

LocationScript is a Bash script designed to periodically retrieve the current location of a device using Termux and send the data to a specified API endpoint. The script logs the location updates and any errors to a log file.

## Features

- Retrieves current location using network provider via Termux.
- Sends location data to a specified API endpoint.
- Logs successful updates and errors to a log file.
- Configurable API URL, device ID, and update interval.

## Prerequisites

- Termux installed on the device.
- `termux-api` package installed in Termux for location access.
- `jq` installed for JSON parsing.
- `curl` installed for sending HTTP requests.

## Usage

```bash
./location.sh [-u API_URL] [-d DEVICE_ID] [-i INTERVAL]
```

- `-u API_URL`: The URL of the API endpoint to send location data to. Default is `http://192.168.0.109:3000/location`.
- `-d DEVICE_ID`: The ID of the device. Default is `esp32-12376`.
- `-i INTERVAL`: The interval (in seconds) between location updates. Default is `2` seconds.

### Examples

```bash
# Use default values
./location.sh

# Specify custom API URL
./location.sh -u http://example.com/location

# Specify custom device ID
./location.sh -d my-device-001

# Specify custom update interval
./location.sh -i 5
```

## Script Details

```bash
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
```

## License

This project is licensed under the MIT License.
