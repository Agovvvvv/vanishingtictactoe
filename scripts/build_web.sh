#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the path to the .env file relative to the script location or project root
ENV_FILE=".env" # Look for .env in the current directory (project root when run via npm)

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE" >&2
    exit 1
fi

# Load environment variables from .env file
# Handles empty lines and comments, exports variables
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)

# Check if required variables are set (optional but recommended)
if [ -z "$FIREBASE_WEB_API_KEY" ]; then
    echo "Error: FIREBASE_WEB_API_KEY is not set in $ENV_FILE" >&2
    exit 1
fi
# Add checks for other required variables here...

# Run the flutter build command with dart-define
# Use \ at the end of lines for readability if desired
echo "Starting Flutter web build with Firebase configuration..."
flutter build web --release \
  --dart-define=FIREBASE_WEB_API_KEY="$FIREBASE_WEB_API_KEY" \
  --dart-define=FIREBASE_WEB_APP_ID="$FIREBASE_WEB_APP_ID" \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID="$FIREBASE_WEB_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_WEB_PROJECT_ID="$FIREBASE_WEB_PROJECT_ID" \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN="$FIREBASE_WEB_AUTH_DOMAIN" \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET="$FIREBASE_WEB_STORAGE_BUCKET" \
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID="$FIREBASE_WEB_MEASUREMENT_ID" \
  --dart-define=FIREBASE_WEB_DATABASE_URL="$FIREBASE_WEB_DATABASE_URL"

echo "Flutter web build completed successfully."

exit 0
