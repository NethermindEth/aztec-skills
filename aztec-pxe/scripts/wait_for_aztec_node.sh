#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <node-url> [timeout-seconds] [interval-seconds]

Polls node_getNodeInfo until the Aztec node responds or timeout is reached.

Examples:
  $0 http://localhost:8080
  $0 https://devnet.aztec-labs.com/ 90 3
USAGE
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required." >&2
  exit 1
fi

node_url="$1"
timeout_seconds="${2:-60}"
interval_seconds="${3:-2}"

start_epoch="$(date +%s)"
payload='{"jsonrpc":"2.0","method":"node_getNodeInfo","params":[],"id":1}'

while true; do
  now_epoch="$(date +%s)"
  elapsed="$((now_epoch - start_epoch))"

  if [[ "$elapsed" -ge "$timeout_seconds" ]]; then
    echo "Error: timed out waiting for Aztec node after ${timeout_seconds}s: $node_url" >&2
    exit 1
  fi

  response="$(curl -sS --max-time 8 -H 'content-type: application/json' -d "$payload" "$node_url" || true)"

  if [[ "$response" == *'"result"'* ]]; then
    echo "Node ready: $node_url"
    exit 0
  fi

  echo "Waiting for node... (${elapsed}s elapsed)"
  sleep "$interval_seconds"
done
