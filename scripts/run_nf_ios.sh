#!/bin/bash

# NutraFlow iOS Runner Script

DEVICE_NAME="iPhone 15"

echo "🚀 Starting NutraFlow on iOS Simulator..."

# Boot simulator if not already running
xcrun simctl boot "$DEVICE_NAME" 2>/dev/null

# Open Simulator app
open -a Simulator

# Wait a bit for simulator to fully boot
sleep 3

# Run Flutter app
flutter run -d "$DEVICE_NAME"
