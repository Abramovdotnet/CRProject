#!/bin/bash

# Get the device ID of the booted simulator
DEVICE_ID=$(xcrun simctl list devices | grep Booted | awk -F'[()]' '{print $2}')

if [ -z "$DEVICE_ID" ]; then
    echo "Error: No booted simulator found"
    exit 1
fi

# Get the app container path
APP_CONTAINER=$(xcrun simctl get_app_container "$DEVICE_ID" com.CRProject data)

if [ -z "$APP_CONTAINER" ]; then
    echo "Error: Could not find app container"
    exit 1
fi

# Path to the errors file
ERRORS_FILE="$APP_CONTAINER/Library/Application Support/CRProject/Supportive/Errors.txt"

# Check if file exists
if [ -f "$ERRORS_FILE" ]; then
    echo "Reading errors from: $ERRORS_FILE"
    echo "----------------------------------------"
    cat "$ERRORS_FILE"
    echo "----------------------------------------"
else
    echo "Error: Errors.txt file not found at $ERRORS_FILE"
    exit 1
fi 