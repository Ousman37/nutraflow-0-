#!/bin/bash
set -euo pipefail

echo "🚀 Starting NutraFlow on iOS Simulator..."

# Target the dedicated NutraFlow simulator
DEVICE_ID="A6706F3F-D552-47F8-8967-BFB95CF64576"
DEVICE_NAME="NutraFlow Simulator"

echo "📱  Device : $DEVICE_NAME"
echo "🆔  UDID   : $DEVICE_ID"

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator
sleep 2

flutter run -d "$DEVICE_ID"
