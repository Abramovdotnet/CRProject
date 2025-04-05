#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# First, try to build the application
echo "Attempting to build the application..."
if ! xcodebuild -scheme CRProject -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build; then
    echo "Build failed. Showing build errors:"
    exit 1
fi

echo "Build successful. Checking for runtime errors..."

# Find the running simulator
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep "Booted" | awk -F'[()]' '{print $2}' | head -n 1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "No running iPhone 16 Pro simulator found. Please start the simulator first."
    exit 1
fi

# Get the app's data container
APP_CONTAINER=$(xcrun simctl get_app_container "$SIMULATOR_ID" com.CRProject data)

if [ -z "$APP_CONTAINER" ]; then
    echo "Could not find app container. Make sure the app is installed on the simulator."
    exit 1
fi

ERRORS_FILE="$APP_CONTAINER/Library/Application Support/CRProject/Supportive/Errors.txt"

echo "Reading errors from: $ERRORS_FILE"
echo "----------------------------------------"

if [ -f "$ERRORS_FILE" ]; then
    cat "$ERRORS_FILE"
    echo "----------------------------------------"
    echo "Removing errors file..."
    rm "$ERRORS_FILE"
else
    echo "No errors found in the log file."
    echo "----------------------------------------"
fi 