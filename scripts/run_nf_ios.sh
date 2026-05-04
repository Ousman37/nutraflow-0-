#!/bin/bash
set -euo pipefail

echo "🚀 Starting NutraFlow on iOS Simulator..."

PREFERRED_UDID="A6706F3F-D552-47F8-8967-BFB95CF64576"
PREFERRED_NAME="NutraFlow Simulator"

# ── Check if the preferred simulator is available ──────────────────────────
is_available() {
  xcrun simctl list devices available 2>/dev/null | grep -q "$1"
}

if is_available "$PREFERRED_UDID"; then
  DEVICE_ID="$PREFERRED_UDID"
  DEVICE_NAME="$PREFERRED_NAME"
  echo "📱  Device : $DEVICE_NAME"
  echo "🆔  UDID   : $DEVICE_ID"
else
  echo "⚠️  Preferred simulator ($PREFERRED_NAME) is unavailable."

  # ── Try to find any available iPhone simulator ────────────────────────────
  DEVICE_ID=$(xcrun simctl list devices available 2>/dev/null \
    | grep -E "iPhone" \
    | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' \
    | head -1 || true)

  if [[ -z "$DEVICE_ID" ]]; then
    echo ""
    echo "❌  No iOS simulators are available on this machine."
    echo ""
    echo "   The iOS simulator runtime is not installed."
    echo "   To fix this:"
    echo "   1. Open Xcode"
    echo "   2. Go to Settings (⌘,) → Platforms"
    echo "   3. Find iOS 26 and click the ⬇️  download button"
    echo "   4. Wait for the download to finish (~2–4 GB)"
    echo "   5. Run this script again"
    echo ""
    exit 1
  fi

  DEVICE_NAME=$(xcrun simctl list devices available 2>/dev/null \
    | grep "$DEVICE_ID" \
    | sed 's/ (.*//' \
    | xargs)

  echo "📱  Falling back to: $DEVICE_NAME"
  echo "🆔  UDID: $DEVICE_ID"
fi

# Boot only this device (no-op if already booted)
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

# Open Simulator.app focused on THIS device — won't disturb other running simulators
open -a Simulator --args -CurrentDeviceUDID "$DEVICE_ID"

# Wait until the device reports "Booted" before handing off to flutter
echo "⏳  Waiting for simulator to finish booting..."
until xcrun simctl list devices 2>/dev/null | grep "$DEVICE_ID" | grep -q "Booted"; do
  sleep 1
done
echo "✅  Simulator ready."

flutter run -d "$DEVICE_ID"
