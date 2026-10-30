#!/usr/bin/env bash
# Runs a debug build on a connected phone against the local ToDoList server (port 8080 by default).
#   Android over USB: `adb reverse` makes the phone's localhost:8080 reach this computer.
#   iPhone: the app uses this computer's Wi-Fi address, so both must be on the same network.
# Emulators and simulators need none of this: a plain `flutter run` already reaches the local server.
#
# Usage: tool/run_on_device.sh [device-id] [more flutter run arguments]
set -euo pipefail

port="${TODO_SERVER_PORT:-8080}"
device_id=""
if [[ $# -gt 0 && "$1" != -* ]]; then
  device_id="$1"
  shift
fi

# Picks the requested device, or the first physical one: prints "<id> <targetPlatform>".
selected="$(flutter devices --machine 2>/dev/null | DEVICE_ID="$device_id" python3 -c '
import json, os, sys
wanted = os.environ["DEVICE_ID"]
devices = [d for d in json.load(sys.stdin) if not d.get("emulator") and d.get("targetPlatform", "").startswith(("android", "ios"))]
devices = [d for d in devices if not wanted or d["id"] == wanted]
if devices:
    print(devices[0]["id"], devices[0]["targetPlatform"])
')"
if [[ -z "$selected" ]]; then
  echo "No connected Android phone or iPhone${device_id:+ with id $device_id}; see \`flutter devices\`." >&2
  exit 1
fi
read -r device_id platform <<<"$selected"

case "$platform" in
  android*)
    adb -s "$device_id" reverse "tcp:$port" "tcp:$port"
    api_url="http://localhost:$port"
    ;;
  ios)
    ip="$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || true)"
    if [[ -z "$ip" ]]; then
      echo "Could not find this computer's Wi-Fi address; pass --dart-define=API_BASE_URL yourself." >&2
      exit 1
    fi
    api_url="http://$ip:$port"
    ;;
esac

if ! curl -sf -m 3 "http://localhost:$port/health" >/dev/null; then
  echo "Warning: no server answers on localhost:$port; start it with ./gradlew :server:run in ToDoList." >&2
fi

echo "Running on $device_id ($platform) against $api_url"
exec flutter run -d "$device_id" --dart-define=API_BASE_URL="$api_url" "$@"
