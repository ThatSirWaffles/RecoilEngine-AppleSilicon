#!/bin/bash
# Fetch the pinned BYAR-Chobby launcher configuration used by packaging.
set -euo pipefail

BAR="${BAR:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG_COMMIT="e0217bd2064821ac66afe760faa6c3d755287a84"
CONFIG_SHA256="d37bf2a8c5b5ce3e2728b9df8db2f04b46b0a4dc1ff1e34df4d0b8b495cbfc1"
CONFIG_URL="https://raw.githubusercontent.com/beyond-all-reason/BYAR-Chobby/${CONFIG_COMMIT}/dist_cfg/config.json"
OUT_DIR="${BAR_CHOBBY_CONFIG_DIR:-$BAR/deps/byar-chobby-config-$CONFIG_COMMIT}"
OUT_FILE="$OUT_DIR/config.json"

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print tolower($1)}'
  else
    sha256sum "$1" | awk '{print tolower($1)}'
  fi
}

mkdir -p "$OUT_DIR"
if [ ! -f "$OUT_FILE" ] || \
   [ "$(sha256 "$OUT_FILE")" != "$CONFIG_SHA256" ]; then
  tmp="$OUT_FILE.tmp.$$"
  trap 'rm -f "$tmp"' EXIT
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --retry-delay 2 --silent --show-error \
      "$CONFIG_URL" -o "$tmp"
  else
    python3 - "$CONFIG_URL" "$tmp" <<'PY'
import sys
import urllib.request

with urllib.request.urlopen(sys.argv[1]) as response, open(sys.argv[2], "wb") as output:
    output.write(response.read())
PY
  fi
  actual="$(sha256 "$tmp")"
  [ "$actual" = "$CONFIG_SHA256" ] || {
    echo "FATAL: checksum mismatch for pinned BYAR-Chobby config" >&2
    echo "  expected: $CONFIG_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  }
  mv "$tmp" "$OUT_FILE"
  trap - EXIT
fi

python3 - "$OUT_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as config_file:
    config = json.load(config_file)

if "chobby_config.json" not in config.get("json_files", {}):
    raise SystemExit("FATAL: pinned BYAR-Chobby config has no chobby_config.json")
if not any(setup.get("downloads", {}).get("games") for setup in config.get("setups", [])):
    raise SystemExit("FATAL: pinned BYAR-Chobby config has no game download tags")
PY

printf '%s\n' "$OUT_FILE"